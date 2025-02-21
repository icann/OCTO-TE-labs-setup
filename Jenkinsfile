@Library('ICANN_LIB') _

properties([[$class: 'BuildDiscarderProperty',
             strategy: [$class: 'LogRotator',
             artifactDaysToKeepStr: '0',
             artifactNumToKeepStr: '0',
             daysToKeepStr: '1',
             numToKeepStr: '10']]]
)

node('okd-general-worker-docker') {

    def utils = new icann.Utilities()
    def dockerImagesToBuild = [:]
    
    utils.notifyBuild('STARTED', 'pe_build')
    
    try {
        stage('Checkout repo') {
            checkout scm
        }

        stage('Test Java 11') {
            utils.mvn(args: '-V clean -Djava.version=11', jdkVersion: 'jdk11')
        }

        stage('Test Java 17') {
            utils.mvn(args: '-V clean -Djava.version=17', jdkVersion: 'jdk17')
        }

        stage('Clean and Analyze Dependencies') {
            utils.mvn(args: '-V clean', jdkVersion: 'jdk21')
            dockerImagesToBuild = utils.analyzeDockerImagesToBuild()
            dockerImagesToBuild.put('pe-monitoring', true)
        }

        stage('Sonar scan') {
            withSonarQubeEnv('ICANN') {
                utils.mvn(args: '-V clean package sonar:sonar', jdkVersion:'jdk21')
            }
        }

        stage('Build pe-monitoring App image') {
            dockerImagesToBuild.each { key, val ->
                utils.sendNotification(slackChannel: 'pe_build', sendSlackMessage: true, buildStatus: 'STARTED', customMessage: 'Building pe-monitoring App docker image')
                utils.mvn(args: 'deploy -P build-image jib:dockerBuild', jdkVersion:'jdk21')
                utils.sendNotification(slackChannel: 'pe_build', sendSlackMessage: true, buildStatus: 'STARTED', customMessage: 'Pushing Image pe-monitoring to docker registry')
                utils.pushImageToRegistryTrunkBased(DTROrg: 'web-extra', DTRRepo: key, dockerImageName: key, forcePush:"true")
            }
        }

        stage('Build and Store Helm') {
            tag_details = utils.tagHelmChart(directory: "helm/pe-monitoring", registry: "container-registry-dev.icann.org/")
            utils.pushHelmChart(directory: 'helm/pe-monitoring', artifactoryPath: 'icann')
        }

        stage('trigger spinnaker webhook') {
            imageTag = utils.generateDockerTag();
            utils.spinnakerTrigger(chart: tag_details['chart'], version: tag_details['version'], webhook: 'pe-monitoring', dockertag: imageTag)
        }

        stage('Notify engineers') {
            utils.notifyBuild('SUCCESSFUL', 'pe_build')
        }

    } catch(e) {
        currentBuild.result = "FAILURE while running on node label " + label
        utils.sendNotification(sendEmail: true, emailRecipient: 'shane.emery@icann.org', buildStatus: currentBuild.currentResult)
        throw e
    }
}
