
*Repository to relocate from*: 100mik/carvel-demo:1.0.0

##### Steps to relocate and add 
- `imgpkg pull -b 100mik/carvel-demo:1.0.0 --to-repo <local-repo-location>` (Do this pre-demo)
- `kctrl package repo add -r carvel-demo --url <local-repo-location>:1.0.0 -n installs`