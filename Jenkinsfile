pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '747030889682'
        ECR_REPOSITORY = 'spark'
        EKS_CLUSTER = 'spark-cluster'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}"

        // Every Jenkins build gets its own image version
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out Spark source code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Spark Docker image...'

                dir('app') {
                    sh '''
                        docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Login to ECR') {
            steps {
                echo 'Authenticating Docker with Amazon ECR...'

                sh '''
                    aws ecr get-login-password \
                        --region ${AWS_REGION} \
                    | docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                echo 'Pushing Spark image to ECR...'

                sh '''
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Configure EKS') {
            steps {
                echo 'Configuring kubectl for Spark EKS cluster...'

                sh '''
                    aws eks update-kubeconfig \
                        --region ${AWS_REGION} \
                        --name ${EKS_CLUSTER}
                '''
            }
        }

        stage('Deploy with Helm') {
            steps {
                echo 'Deploying Spark to EKS...'

                sh '''
                    helm upgrade --install spark ./helm/spark \
                        --set image.repository=${IMAGE_NAME} \
                        --set image.tag=${IMAGE_TAG} \
                        --wait
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying Spark deployment...'

                sh '''
                    kubectl get pods
                    kubectl get svc
                    kubectl get ingress
                '''
            }
        }
    }

    post {
        success {
            echo "Spark deployment successful! Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        }

        failure {
            echo 'Spark deployment failed. Check the Jenkins console output.'
        }
    }
}