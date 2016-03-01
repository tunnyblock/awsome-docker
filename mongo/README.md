Start mongoDB

```sh
$ docker-compose up -d
```

Check mongo status

```sh
docker exec mongo mongo 127.0.0.1:27017 --eval 'db.stats()'
MongoDB shell version: 3.2.3
connecting to: 127.0.0.1:27017/test
{
    "db" : "test",
    "collections" : 0,
    "objects" : 0,
    "avgObjSize" : 0,
    "dataSize" : 0,
    "storageSize" : 0,
    "numExtents" : 0,
    "indexes" : 0,
    "indexSize" : 0,
    "fileSize" : 0,
    "ok" : 1
}
```

Add user to mongo

```sh
$ docker exec -it mongo mongo admin
connecting to: admin
> db.createUser({ user: 'jsmith', pwd: 'some-initial-password', roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });
Successfully added user: {
    "user" : "jsmith",
    "roles" : [
        {
            "role" : "userAdminAnyDatabase",
            "db" : "admin"
        }
    ]
}
```

Check mongo logs

```sh
$ docker logs mongo
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] MongoDB starting :
pid=1 port=27017 dbpath=/data/db 64-bit host=bca15f3420e3
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] db version v3.2.3
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] git version:
b326ba837cf6f49d65c2f85e1b70f6f31ece7937
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] OpenSSL version:
OpenSSL 1.0.1e 11 Feb 2013
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] allocator: tcmalloc
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] modules: none
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] build environment:
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten]     distmod: debian71
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten]     distarch: x86_64
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten]     target_arch: x86_64
2016-03-01T07:39:17.611+0000 I CONTROL  [initandlisten] options: {}
2016-03-01T07:39:17.677+0000 I -        [initandlisten] Detected data files in
/data/db created by the 'wiredTiger' storage engine, so setting the active
storage engine to 'wiredTiger'.
2016-03-01T07:39:17.677+0000 W -        [initandlisten] Detected unclean
shutdown - /data/db/mongod.lock is not empty.
2016-03-01T07:39:17.677+0000 W STORAGE  [initandlisten] Recovering data from
the last clean checkpoint.
2016-03-01T07:39:17.677+0000 I STORAGE  [initandlisten] wiredtiger_open config:
create,cache_size=3G,session_max=20000,eviction=(threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,archive=true,path=journal,compressor=snappy),file_manager=(close_idle_time=100000),checkpoint=(wait=60,log_size=2GB),statistics_log=(wait=0),
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten]
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten] ** WARNING:
/sys/kernel/mm/transparent_hugepage/enabled is 'always'.
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten] **        We suggest
setting it to 'never'
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten]
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten] ** WARNING:
/sys/kernel/mm/transparent_hugepage/defrag is 'always'.
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten] **        We suggest
setting it to 'never'
2016-03-01T07:39:21.311+0000 I CONTROL  [initandlisten]
2016-03-01T07:39:21.335+0000 I FTDC     [initandlisten] Initializing full-time
diagnostic data capture with directory '/data/db/diagnostic.data'
2016-03-01T07:39:21.335+0000 I NETWORK  [initandlisten] waiting for connections
on port 27017
2016-03-01T07:39:21.335+0000 I NETWORK  [HostnameCanonicalizationWorker]
Starting hostname canonicalization worker
2016-03-01T07:39:22.005+0000 I FTDC     [ftdc] Unclean full-time diagnostic
data capture shutdown detected, found interim file, some metrics may have been
lost. OK
```

