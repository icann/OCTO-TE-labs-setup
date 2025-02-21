# Fill out this Readme...use below as a quideline

This application is designed to be built and run daily, in order to verify that all Platform Engineering services related to application CI/CD pipelines are working properly.

1. spinnaker defined pipeline and hooks
2. jenkins hooks
3. container registry hooks
4. artifactory docker and helm chart hooks
5. sonarqube scans
6. openshift OKD dev and prod cluster
7. redis sentinel cluster integration and test
8. kafka and zookeeper cluster integration and test via api

## Technologies

* Java 17
* Maven 3.6+
* Spring Boot 2.6.0+
* Redis
* Kafka
* Actuator Prometheus metrics

## Setup

git clone https://github.com/icann/pe-monitoring.git

Please check configuration of this Jenkins Cron Job:
* https://build.icann.org/view/Platform%20Engineering/job/pe-monitoring-cron/

## Build

mvn clean compile package

## Run 

DEV
export redis_password=*******
export redis_check=true
export SPRING_PROFILES_ACTIVE=qa
* java -jar target/pemonitoring-2.2.4.jar

PROD LAX
export redis_password=*******
export redis_check=true
export SPRING_PROFILES_ACTIVE=lax
* java -jar target/pemonitoring-2.2.4.jar

PROD DC
export redis_password=*******
export redis_check=true
export SPRING_PROFILES_ACTIVE=lax
* java -jar target/pemonitoring-2.2.4.jar

* Use any REST API tester and post few messages to API http://localhost:8080/kafka/publish in query parameter "message".

* Message post : http://localhost:8080/kafka/publish?message=Alphabet

* Observe the console logs:

* Output
* 2020-05-24 23:36:47.132  INFO 2092 --- [nio-9000-exec-4] c.h.k.demo.service.KafKaProducerService  : Message sent -&gt; Alphabet

* 2020-05-24 23:36:47.138  INFO 2092 --- [ntainer#0-0-C-1] c.h.k.demo.service.KafKaConsumerService  : Message recieved -&gt; Alphabet

## Environments

* okd-dev-dc
* okd-prod-dc
* okd-prod-lax

## Configurations

The application helm chart publishes openshift routes:
* https://pe-monitoring.apps.openshift-dev-dc.icann.org/
* https://pe-monitoring.apps.openshift-prod-dc.icann.org/
* https://pe-monitoring.apps.openshift-prod-lax.icann.org/

## Deployment

* Jenkins Will automatically recieve a hook to build docker image and push helm chart, based on master branch updates.
* Trigger `Full Test` Pipeline in spinnaker pe-monitoring. (Check that everything is working fine on https://pe-monitoring.apps.openshift-dev-dc.icann.org/actuator/health.
* Check logs for the container.
* Check that everything is fine on https://pe-monitoring.apps.openshift-prod-lax.icann.org/actuator/health.
