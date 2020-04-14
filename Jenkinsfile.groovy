pipeline {
  agent {
    docker {
      image 'ruby:2.6.3'
      args '-v $HOME/bundle_cache/Backend/bundle:/usr/local/bundle'
    }
  }

  parameters {
    string(name: 'SLACK_CHANNEL_1',
           description: 'Default Slack channel to send messages to',
           defaultValue: '#auto_deployment')

    string(name: 'SLACK_CHANNEL_2',
           description: 'Default Slack channel to send messages to',
           defaultValue: '#backend')
  }

  environment {
    // URL configuration
    RCOV_REPORT_URL     = "${env.BUILD_URL}rcov"
    CONSOLE_REPORT_URL  = "${env.BUILD_URL}console"

    // Git configuration
    GIT_COMMITTER_NAME = sh(
      script: "git --no-pager show -s --format='%cn'",
      returnStdout: true
    ).trim()
    GIT_COMMITTER_EMAIL = sh(
      script: "git --no-pager show -s --format='%ce'",
      returnStdout: true
    ).trim()
    GIT_COMMITTER_DATE = sh(
      script: "git --no-pager show -s --format='%cD'",
      returnStdout: true
    ).trim()
    GIT_COMMIT_URL = "${env.GIT_URL.minus('.git')}" + '/commit/' + "${env.GIT_COMMIT}"
    GIT_BRANCH_SPECIFIER = "refs/heads/${env.GIT_BRANCH}"

    // Slack configuration
    SLACK_COLOR_DANGER  = '#E01563'
    SLACK_COLOR_WARNING = '#FFC300'
    SLACK_COLOR_GOOD    = '#3EB991'
    SLACK_COLOR_INFO    = '#6ECADC'

    SLACK_COMMIT_MESS = "*Commit:* <${env.GIT_COMMIT_URL}|${env.GIT_COMMIT}> - ${env.GIT_BRANCH_SPECIFIER}\n" +
                        "*Author:* ${env.GIT_COMMITTER_NAME} <${env.GIT_COMMITTER_EMAIL}>\n" +
                        "*Date:*   ${env.GIT_COMMITTER_DATE}"
    SLACK_BUILD_RESULT = "${currentBuild.currentResult}"
    SLACK_BUILD_JOB_MESS = "Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}"
    SLACK_BUILD_URL_MESS = "More info at: <${env.BUILD_URL}|Build ${env.BUILD_NUMBER}>"
    SLACK_BUILD_RCOV_MESS = "Rcov report at: <${env.RCOV_REPORT_URL}|Rcov report>"
    SLACK_BUILD_CONSOLE_MESS = "Console output at: <${env.CONSOLE_REPORT_URL}|Console output>"
    SLACK_USER_GROUPS = '@backend_devs'
    SLACK_BUILD_UNSTABLED_MESS = "*UNSTABLED* rồi nha ${env.SLACK_USER_GROUPS} ơi"
    SLACK_BUILD_FAILED_MESS = "*FAILED* rồi nha ${env.SLACK_USER_GROUPS} ơi"

    SLACK_SUCCESS_MESS  = "${env.SLACK_BUILD_JOB_MESS}\n" +
                          "${env.SLACK_BUILD_URL_MESS}\n" +
                          "${env.SLACK_BUILD_RCOV_MESS}\n" +
                          "${env.SLACK_BUILD_CONSOLE_MESS}\n" +
                          "\n" +
                          "${env.SLACK_COMMIT_MESS}\n" +
                          "\n"
    SLACK_UNSTABLE_MESS = "${env.SLACK_BUILD_JOB_MESS}\n" +
                          "${env.SLACK_BUILD_URL_MESS}\n" +
                          "${env.SLACK_BUILD_RCOV_MESS}\n" +
                          "${env.SLACK_BUILD_CONSOLE_MESS}\n" +
                          "\n" +
                          "${env.SLACK_COMMIT_MESS}\n" +
                          "\n" +
                          "${env.SLACK_BUILD_UNSTABLED_MESS}\n" +
                          "\n"
    SLACK_FAILURE_MESS  = "${env.SLACK_BUILD_JOB_MESS}\n" +
                          "${env.SLACK_BUILD_URL_MESS}\n" +
                          "${env.SLACK_BUILD_CONSOLE_MESS}\n" +
                          "\n" +
                          "${env.SLACK_COMMIT_MESS}\n" +
                          "\n" +
                          "${env.SLACK_BUILD_FAILED_MESS}\n" +
                          "\n"

    // Email configuration
    EMAIL_TO   = 'jenkins@okiela.com'
    EMAIL_BODY = "<p>Check console output at <a href='${env.CONSOLE_REPORT_URL}'>${env.SLACK_BUILD_JOB_MESS}</a> to view the results.</p>" +
                 "<p><i>(Build log is attached.)</i></p>"
  }

  stages {
    stage('Requirements') {
      steps {
        sh 'apt-get update'
        sh 'apt-get install -y default-libmysqlclient-dev'
        sh 'apt-get install -y libgd-dev'
        sh 'apt-get install -y default-mysql-client'
        sh 'apt-get install -y zip'
        sh 'gem install bundler -v 2.0.2'
        sh 'bundle install --jobs 4 --retry 3'
        sh 'cp config/database.yml.template config/database.yml'
      }
    }

    stage('Unit test') {
      steps {
        // Just for the first time
        // sh 'bundle exec rake db:setup_test'

        // And for another time
        sh 'RACK_ENV=test bundle exec rake db:migrate'
        sh 'RACK_ENV=test bundle exec rake db:seed'

        sh 'rm -rf logs/*'
        sh 'bundle exec rspec'
      }
    }
  }

  post {
    always {
      sh 'zip -r logs.zip logs/*'

      step([
        $class: 'RcovPublisher',
        reportDir: 'coverage/rcov',
        targets: [
          [
            $class: 'hudson.plugins.rubyMetrics.rcov.model.MetricTarget',
            metric: 'TOTAL_COVERAGE',
            healthy: 15,
            unhealthy: 13,
            unstable: 10
          ],
          [
            $class: 'hudson.plugins.rubyMetrics.rcov.model.MetricTarget',
            metric: 'CODE_COVERAGE',
            healthy: 15,
            unhealthy: 13,
            unstable: 10
          ]
        ]
      ])
    }

    success {
      slackSend (
        color: "${env.SLACK_COLOR_GOOD}",
        channel: "${params.SLACK_CHANNEL_1}",
        message: "*SUCCESS:* ${env.SLACK_SUCCESS_MESS}"
      )
    }

    unstable {
      slackSend (
        color: "${env.SLACK_COLOR_WARNING}",
        channel: "${params.SLACK_CHANNEL_2}",
        message: "*UNSTABLE:* ${env.SLACK_UNSTABLE_MESS}"
      )

      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build unstabled in Jenkins: ${env.SLACK_BUILD_JOB_MESS}",
        body: env.EMAIL_BODY
      )
    }

    failure {
      slackSend (
        color: env.SLACK_COLOR_DANGER,
        channel: params.SLACK_CHANNEL_2,
        message: "*FAILURE:* ${env.SLACK_FAILURE_MESS}"
      )

      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build failed in Jenkins: ${env.SLACK_BUILD_JOB_MESS}",
        body: env.EMAIL_BODY
      )
    }
  }
}
