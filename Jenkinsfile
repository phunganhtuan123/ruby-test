pipeline {
  agent {
    docker {
      image 'ruby:2.6.3'
      args '-v $HOME/bundle_cache/Backend/bundle:/usr/local/bundle'
    }
  }

  environment {
    // Email configuration
    EMAIL_TO   = 'phunganhtuan123@gmail.com'
    EMAIL_BODY = "<p>Check console output at</p>"
  }

  stages {
    stage('Requirements') {
      steps {
        sh 'docker-compose build'
        sh 'docker-compose up'
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
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Success",
        body: env.EMAIL_BODY
      )
    }

    unstable {
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build unstabled in Jenkins",
        body: env.EMAIL_BODY
      )
    }

    failure {
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build failed in Jenkins",
        body: env.EMAIL_BODY
      )
    }
  }
}
