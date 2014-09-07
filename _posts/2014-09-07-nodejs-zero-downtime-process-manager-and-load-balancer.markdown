---
layout: post
title: "Node.js Zero Downtime Process Manager and Load Balancer"
date:   2014-09-07 13:49:11
---

As an experienced Rails developer, I have been familiar with plenty of zero downtime rack servers, they are quite easy to deploy and can achieve zero downtime between each new deployment and balancing the server load across different workers.

Node.js seems to have a very different ecosystem and culture, the built in HTTP server has very efficient performance compared to the Ruby's WEBRick, so no need to develop or find third party Node.js app server like Unicorn or Puma in Ruby.

But the HTTP server lacks the convinience to deploy in production, how to achieve zero downtime deployment? Luckily, there is the cluster module http://nodejs.org/api/cluster.html. Although it's still marked as _Stability: 1 - Experimental_, we have been using it in Shou.TV for several months without any issues.

```javascript
var fs = require('fs');
var cluster = require('cluster');

var forkWorkers = function () {
  for (var i = 0; i < require('os').cpus().length; i++) {
    cluster.fork();
  }
};

if (cluster.isMaster) {
  fs.writeFileSync("/tmp/node.cluster.pid", process.pid);

  process.on('SIGUSR2', function () {
    for (var id in cluster.workers) {
      var worker = cluster.workers[id];
      worker.disconnect();
    }
  });

  cluster.on('exit', function (worker, code, signal) {
    cluster.fork();
  });

  forkWorkers();
} else {
  var ShouServer = require('./server');
  new ShouServer().listen(8000);
}
```

Then after updating the code in the production server, I can just send the USR2 signal to the cluster process to load the new server.

```bash
kill -USR2 `cat /tmp/node.cluster.pid`
```

Just after I implemented this cluster mechanism, I found [PM2](https://github.com/Unitech/PM2), which has all the features I wanted and uses the same cluster module. It's always an issue when learning a new technology that you just don't know the best practice and reinvent many better tools and do worse than them.

This is learning.
