# DevOps Microservices CI/CD Project

## Overview
A Docker-based microservices application deployed on AWS EC2 with Jenkins CI/CD, Nginx API Gateway, Prometheus monitoring, and Grafana dashboards.

## Technologies
- AWS EC2
- Python Flask
- Docker and Docker Compose
- Nginx
- Jenkins
- Git and GitHub
- Terraform
- Prometheus
- Grafana

## Architecture
GitHub -> Jenkins -> Docker Compose -> AWS EC2

Client -> Nginx -> User, Product, and Order Services

Prometheus -> Microservices Metrics -> Grafana

## Microservices
| Service | API Endpoint | Health Endpoint |
|---|---|---|
| User Service | /users | /user-health |
| Product Service | /products | /product-health |
| Order Service | /orders | /order-health |

All three Flask services listen on port 5000 inside Docker.

## Docker Deployment
The application uses six containers:
- user-service
- product-service
- order-service
- nginx-proxy
- prometheus
- grafana

Deployment command:

    docker compose -p devops-microservices-assignment up -d --build

Check running containers:

    docker compose -p devops-microservices-assignment ps

## Jenkins CI/CD
The Jenkins pipeline performs:
1. Source code checkout
2. Docker Compose validation
3. Docker image builds
4. Docker Compose deployment
5. Nginx reload
6. API and health endpoint tests

Jenkins Build #5 completed successfully.

## API Gateway
Nginx listens on port 80 and routes requests to the microservices.

Test commands:

    curl http://localhost/users
    curl http://localhost/products
    curl http://localhost/orders

## Monitoring
Prometheus collects metrics from all three microservices and itself.

- Prometheus: port 9090
- Grafana: port 3000
- Flask metrics endpoint: /metrics

All four Prometheus targets were verified as UP.

Grafana uses Prometheus as its data source and displays CPU usage and API request-rate metrics.

## Terraform
Terraform uses the HashiCorp AWS provider version 6.x in the us-east-1 region.

The current Terraform configuration reads existing AWS EC2, VPC, subnet, and security group resources using data sources. It does not provision these resources.

Validate Terraform:

    cd terraform
    terraform validate

## Verified Results
- Jenkins Build #5: SUCCESS
- Docker containers: 6 running
- Microservices: 3 healthy
- API endpoints: HTTP 200
- Prometheus targets: 4 UP
- Grafana database: OK
- Terraform validation: SUCCESS

## GitHub Repository
https://github.com/Raveenjbs/devops-microservices-assignment
