# pi-minecraft-paperMC
Some handy scripts to manage paperMC for a pi. 
Controls startup and shutdown of the minecraft server and can update it as needed.
## get_latest_paperMC useage
Use `get_latest_paperMC.sh` to download the latest build.
It will create a symbolic link to `paperMC` that is used by `minecraft_sever_ctl.sh` to start the sever

If you want to update paperMC regularly use `crontab -e` and add cron job to the end of the crontab for whatever interval you want.

## minecraft_server_ctl usage
Use `minecraft_server_ctl.sh <command>` to control the server. Valid commands are:
|Command|Description|
|--|--|
|`start`| Starts the server|
|`stop`| Stops the server|
|`restart`|Restarts the server|
|`status`|Returns whether the server is running or not|

If the server crashes it will try and restart it after 5 (default) seconds.

If you want to make it startup on boot then use `crontab -e` and add `@reboot <PATH>/minecraft_server_ctl.sh start` to the end of the crontab.