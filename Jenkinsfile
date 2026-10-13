pipeline {
    agent {
        docker {
            image 'node:18.19.0'
            args '--add-host host.docker.internal:host-gateway'
        }
    }

    environment {
        NEXUS_URL = 'host.docker.internal:8081/repository/kijanikiosk-internal/'
        APP_NAME = 'kijanikiosk-payments'
        GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        APP_VERSION = "1.0.0-${GIT_SHA}"
    }

    stages {
        stage('Lint') {
            steps {
                dir('week5/friday') {
                    echo "Running Linter..."
                    sh 'npm ci || true'
                    sh 'npm run lint'
                }
            }
        }

        stage('Build') {
            steps {
                dir('week5/friday') {
                    echo "Building application version ${APP_VERSION}..."
                    sh "npm version ${APP_VERSION} --no-git-tag-version --allow-same-version"
                    sh 'npm run build'
                }
                stash name: 'build-artifact', includes: 'week5/friday/package.json, week5/friday/src/**, week5/friday/test/**'
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        dir('week5/friday') {
                            echo "Running Unit Tests..."
                            sh 'npm test'
                        }
                    }
                }
                stage('Security Audit') {
                    steps {
                        dir('week5/friday') {
                            echo "Running npm audit..."
                            sh 'npm audit --audit-level=high || true'
                        }
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                echo "Archiving artifacts..."
                archiveArtifacts artifacts: 'week5/friday/package.json, week5/friday/src/**', fingerprint: true
            }
        }

        stage('Publish') {
            steps {
                unstash 'build-artifact'
                dir('week5/friday') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            echo "//${NEXUS_URL}:_authToken=${NEXUS_PASS}" > .npmrc
                            echo "Publishing to Nexus..."
                            npm publish --registry=http://${NEXUS_URL}
                            rm .npmrc
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Cleaning workspace..."
            cleanWs()
        }
        success {
            echo "SUCCESS: Artifact ${APP_NAME}@${APP_VERSION} published successfully to Nexus."
        }
        failure {
            echo "FAILURE: The pipeline failed. Notifying the team..."
        }
        changed {
            echo "STATUS CHANGED: The pipeline state has transitioned from its previous run."
        }
    }
}
