# Delta_Onsites_2
## TINY LOGICAL ERROR IN LINE 101 - As of 24/07/2025 9.30 am
- -ge should be changed to -le in the if condition. This is the correct way to compare the number of unused containers vs half of total containers.
## Features 
- dock_bg.sh is the script that gets called by the created service.
- It runs every 100s.
- 3 functions for
  - first one checks if it is an unused container based on CPU usage, and the connection between container and another service/client.
  - second function logs and kills the container
  - third function gets all the other containers in the same network
