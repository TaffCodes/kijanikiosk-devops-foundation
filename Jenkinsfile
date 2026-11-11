pipeline {
  agent any

  environment {
    REGISTRY = "localhost:5000"
    IMAGE_NAME = "kk-payments"
    STAGING_NS = "kijani-staging"
    PROD_NS = "default"
  }

  stages {
    stage('Checkout & Version Computation') {
      steps {
        script {
          env.APP_VERSION = sh(script: "grep '\"version\"' package.json | cut -d '\"' -f4", returnStdout: true).trim()
          env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.FULL_TAG = "${env.APP_VERSION}-${env.GIT_SHA}"
          echo "Building version tag: ${env.FULL_TAG}"
        }
      }
    }

    stage('Provision & Configure Infrastructure (Terraform + Ansible)') {
      steps {
        sh '''
          cd terraform
          terraform init -input=false
          terraform apply -auto-approve -input=false
          cd ../ansible
          ansible-playbook -i inventory.ini site.yml
        '''
      }
    }

    stage('Build & Push Production Container Image') {
      steps {
        sh '''
          docker build --no-cache -t ${REGISTRY}/${IMAGE_NAME}:${FULL_TAG} -t ${REGISTRY}/${IMAGE_NAME}:1.0.0 -f Dockerfile.production .
          docker push ${REGISTRY}/${IMAGE_NAME}:${FULL_TAG}
          docker push ${REGISTRY}/${IMAGE_NAME}:1.0.0
          minikube image load ${REGISTRY}/${IMAGE_NAME}:1.0.0 || true
        '''
      }
    }

    stage('Deploy to Staging (kijani-staging)') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          kubectl apply -f k8s/configmap-staging.yaml -n ${STAGING_NS}
          kubectl apply -f k8s/kk-payments-deployment.yaml -n ${STAGING_NS}
          kubectl apply -f k8s/kk-payments-service.yaml -n ${STAGING_NS}
        '''
      }
    }

    stage('Staging Smoke Test & Receipt Chain Check') {
      when {
        branch 'main'
      }
      steps {
        sh './scripts/smoke-test.sh kijani-staging staging 13001'
      }
    }

    stage('Production Approval Gate') {
      when {
        branch 'main'
      }
      steps {
        script {
          def approvalReason = input(
            id: 'ProdDeployApproval',
            message: 'Staging smoke tests and serverless receipt chain passed. Approve production deployment?',
            parameters: [
              string(
                defaultValue: 'Staging smoke test and receipt chain verified healthy',
                description: 'Mandatory audit reason for promoting release to production',
                name: 'APPROVAL_REASON'
              )
            ]
          )
          echo "[AUDIT LOG] Production deployment approved. Reason: ${approvalReason}"
        }
      }
    }

    stage('Deploy to Production (default)') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          kubectl apply -f k8s/configmap-prod.yaml -n ${PROD_NS}
          kubectl apply -f k8s/kk-payments-deployment.yaml -n ${PROD_NS}
          kubectl apply -f k8s/kk-payments-service.yaml -n ${PROD_NS}
          ./scripts/smoke-test.sh default production 13002
        '''
      }
    }
  }
}
