
# Hotcake

> "My favorite health club is the International House of Hotcakes" said no one ever.

Hotcake is a simple API for tagging infrastructure assets. Tags are indexed into ElasticSearch and take the following JSON format:

```
{
    "application" : "bluespar", 
    "environment" : "prod", 
    "infra_type" : "cluster", 
    "infra_name" : "MAIN-B",
    "tags" : ["FIT", "VUL-21AA"],
    "properties" : {
        "stack" :"test",
        "owner" :"FSCCP"
    }
}
```

In the above document,`tags` are simply an array of values, while `properties` are name-value pairs. A cluster, named `MAIN-B` has been tagged with `FIT` and `VUL-21AA` along with two property values (`stack = test` and `owner = FSCCP`). This cluster is owned by the application named `bluespar` in a `prod` environment. 

## API

The API is fairly straightforward. For instance, to create tags for a cluster called "MAIN" associated with an application named "flapjack" in the "pci" environment, simply HTTP POST tags in the following JSON document form:

```
{"tags": ["vul", "fit"] }
```

to the following URL `http://<hostname:port>/applications/pci/flapjack/cluster/MAIN`. 

As you can see the URL pattern is essentially `/applications/<env>/<app name>/<infra type>/<infra type name>`. Likewise, if you want to associate a property to this same cluster, you would post a JSON document as follows:

```
{"properties": {"owner":"dl@acme.com"} }
```

## Running Hotcake

Hotcake is written in Ruby; accordingly, clone the repo and run:

```
bundle install
```

It's assumed by default that ElasticSearch is running locally on port 9200. You can easily fire up a local ElasticSerach instance via Docker like so:

```
docker run --name es01 --net elastic -p 9200:9200 -e discovery.type=single-node  -e xpack.security.enabled=false -it docker.elastic.co/elasticsearch/elasticsearch:8.7.1
```

To run Hotcake, type:

```
bundle exec ruby lib/tag_app.rb
```

By default, Hotcake listens on port 4576. You can HTTP POST documents to it vai CURL using the above URL pattern. 

To take Hotcake for a spin, execute the following HTTP POST: 

```
http://localhost:4567/applications/prod/hootch/cluster/default
```

With this JSON body: 

```
{"properties": {"owner":"anyone@acme.corp" }}
```

You can do this via CURL or something like POSTMAN. Then do an HTTP GET like so:

```
http://localhost:4567/applications/prod/hootch
```

And you should see:

```
"{
    "application":"hootch",
    "environment":"prod",
    "infra_type":"cluster",
    "infra_name":"default",
    "properties":{"owner":"anyone@acme.corp"}
}"
```

Of course, the whole point of Hotcake is to associate meta-data with infrastructure assets; accordingly, finding matching documents is where things shine. For instance, try these two POSTS:

```
http://localhost:4567/applications/prod/gusto/cluster/TEST-1
```

With 

```
{"tags": ["fit", "deprecated"] }
```

Followed by:

```
http://localhost:4567/applications/prod/aye/cluster/MAIN-B
```

With
```
{"tags": ["fit"] }
```

Next, perform an HTTP GET against this url: `http://localhost:4567/applications?tags=fit` and you should see both application's clusters returned (i.e. `MAIN-B` and `TEST-1`). 

