# Sub_Recon

This tool was devised as something that I think would be beneficial for a lot of Beginners starting out. This is just a basic script that aids in the initial 
phases of Reconnaissance that a Security Researcher has to perform:- to `Map out all the subdomains for a wildcard.`

![Tool Banner](/Sub_Recon.png)
This Repo is maintained by [P4rC3L](https://github.com/P4rC3L) and [an-sh7](https://github.com/an-sh7).

### How to Use? 
- Download the script, and give it executable permission using this command: `sudo chmod +x sub_recon.sh`
- Run the file using the following command: `./sub_recon.sh -u <DOMAIN_NAME>`
- A file named after the target (e.g. `tesla_com.txt`) would be created containing all the results found through automation. <br>Tools used: [`Subfinder`](https://github.com/projectdiscovery/subfinder), [`Assetfinder`](https://github.com/tomnomnom/assetfinder) & [`Sublist3r`](https://github.com/aboul3la/Sublist3r).
- Add the `--ch` switch (e.g. `./sub_recon.sh -u tesla.com --ch`) to also run `status_check.sh` after recon, which visits every discovered host (using `curl`) and prints its HTTP status code (`200`, `301`, `404`, `503`, ...) — colour-coded so you can tell live hosts from dead ones at a glance. These results are saved next to the list as `<domain>_status.txt` (e.g. `tesla_com_status.txt`). Without `--ch`, only subdomain collection runs.
- Down below, you could find out some passive resources listed for other sources. This was done to ensure that the user is able to directly access the needed list with the minimum amount of headache.

> You can use this script to facilitate your own projects. This is the permission that this script is open to public.
---
- Fix_1.0: Added a check to detect the presence of the required tools on the User's system, and install them if unavailable.<br>This check is only performed once, when the script is run for the first time and is then skipped-over for better performance. Delete the `./.sub-recon_ran_already` file in the directory where the script was run initially to re-enable the check.<br>
- Fix_1.2: Added a Banner and Some visual Loading bars. Also added a flag_script for testing purposes. It would be excluded later.<br>
- Fix_1.3: Stripped the URL so that the output files are separated. Ex:-<br> 
> "https[:]//tesla.com" --> "tesla_com.txt"<br>
> "https[:]//tesla.net" --> "tesla_net.txt"
- Fix_1.4: Added `status_check.sh` behind the opt-in `--ch` switch. When you pass `--ch`, every discovered subdomain is visited with `curl` after recon and its HTTP response code is printed (colour-coded) and saved to `<domain>_status.txt`. This lets you quickly spot which hosts are live (`2xx`), redirecting (`3xx`), erroring (`4xx`/`5xx`) or unreachable (`000`).
