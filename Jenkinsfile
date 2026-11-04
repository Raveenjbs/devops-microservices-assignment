
pipeline {
    agent any

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
                sh 'docker compose build'
            }
        }

        stage('Deploy Microservices') {
            steps {
                sh 'docker compose up -d'
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
