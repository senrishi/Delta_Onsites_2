# Delta_Onsites_2
- dock_bg.sh is the script that gets called by the created service.
- It runs every 100s.
- 3 functions for
  - first one checks if it is an unused container based on CPU usage, and the connection between container and another service/client.
  - second function logs and kills the container
  - third function gets all the other containers in the same network
