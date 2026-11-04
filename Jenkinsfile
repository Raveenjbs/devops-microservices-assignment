
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        ECR_REGISTRY = '877270729691.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Docker Compose') {
            steps {
                sh 'docker compose config --quiet'
            }
        }

        stage('Build Docker Images') {
            steps {
                sh 'docker compose -p devops-microservices-assignment build'
            }
        }

        stage('Tag Docker Images for ECR') {
            steps {
                sh '''
                    for service in user-service product-service order-service; do
                        docker tag "${service}:1.0" "${ECR_REGISTRY}/${service}:${IMAGE_TAG}"
                    done
                '''
            }
        }

        stage('Push Docker Images to ECR') {
            steps {
                sh '''
                    set -eu

                    export DOCKER_CONFIG="$(mktemp -d)"
                    trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                    aws ecr get-login-password --region "$AWS_DEFAULT_REGION" |
                        docker login --username AWS --password-stdin "$ECR_REGISTRY"

                    for service in user-service product-service order-service; do
                        docker push "${ECR_REGISTRY}/${service}:${IMAGE_TAG}"
                    done
                '''
            }
        }

        stage('Deploy Microservices') {
            steps {
                sh '''
                    set -eu

                    export DOCKER_CONFIG="$(mktemp -d)"
                    trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                    aws ecr get-login-password --region "$AWS_DEFAULT_REGION" |
                        docker login --username AWS --password-stdin "$ECR_REGISTRY"

                    docker compose -p devops-microservices-assignment -f docker-compose.yml -f docker-compose.ecr.yml pull user-service product-service order-service

                    docker compose -p devops-microservices-assignment -f docker-compose.yml -f docker-compose.ecr.yml up -d --no-build

                    docker exec nginx-proxy nginx -s reload
                '''
            }
        }

        stage('Test API Gateway') {
            steps {
                sh '''
                    curl --fail http://localhost/
                    curl --fail http://localhost/users
                    curl --fail http://localhost/products
                    curl --fail http://localhost/orders
                    curl --fail http://localhost/user-health
                    curl --fail http://localhost/product-health
                    curl --fail http://localhost/order-health
                '''
            }
        }
    }

    post {
        success {
            echo 'Microservices CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }
    }
}
