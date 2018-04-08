# dotus
A ruby Kubernetes api reader\persistor

Reads the objects off of an kubernetes api endpoint and saves snapshots of all objects over time. This isnt really better than a kibana+elastic search setup but its hassle free and saves api reads locally.

## Setup
clone this repository and run bundle install.

```
git clone https://github.com/zeari/dotus.git
cd dotus
bundle install
```


## Config
Edit config.yaml in your preferred editor.
Youll have to get a token from your kubernertes instance. More info on how to do this in the kubernetes docs.


```Yaml
config:
  type: kubernetes # no need to change this
  url: my.kube.example.com:443 # address:port - the script accesses https://<url>
  token: eytokentokenkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AkentokenMXpwExDfR9jJ6rhxGqJreB3payKjy2d8AMXpwExDfR9jJ6rhxGqJreB3payKjy2d8A
  directory: /home/mykube # directory to save data in
  interval: 1    # collect all infor every <interval> minutes
  kube_config_path: '' # untested - get access info off of your .kube/config
```

## Run
```ruby dotus.rb```


```you@machine /home/dotus$> ruby dotus.rb 
getting pods(16)
getting secrets- cant get secrets: secrets is forbidden: User "system:serviceaccount:management-infra:management-admin" cannot list secrets at the cluster scope: User "system:serviceaccount:management-infra:management-admin" cannot list all secrets in the cluster
getting services(20)
getting nodes(5)
getting replication_controllers(6)
getting resource_quotas(1)
getting limit_ranges(1)
getting persistent_volumes(14)
getting persistent_volume_claims(5)
getting component_statuses(3)
getting service_accounts(103)
  0.090000   0.020000   0.110000 (  0.243072)
sleeping until 2018-04-08 14:33:09 +0300
...
```

## UI\API
Small sinatra based web UI thats shows changes(diffs) over time.

```ruby rest.rb```

Access at http://localhost:4567/view_obj_history.html?path=pods/prometheus-0 and it should look something like this:
![UI screenshot](/ui_screenshot.png)



## Technical Overview

Accessing kubernetes api with https://github.com/abonas/kubeclient
each object is saved as json in its path such as: `pods/mypod1` or `services/myservice` in a git repo.

### why git? 

Because:
* it already exists on most machines and its pretty flexible.
* it compresses the text changes nicely (you can test this out with https://github.com/github/git-sizer).

