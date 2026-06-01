# Sub_Recon

This tool was devised as something that I think would be beneficial for a lot of Beginners starting out. This is just a basic script that aids in the initial 
phases of Reconnaissance that a Security Researcher has to perform:- to `Map out all the subdomains for a wildcard.`

![Tool Banner](/Sub_Recon.png)
This Repo is maintained by [P4rC3L](https://github.com/P4rC3L) and [an-sh7](https://github.com/an-sh7).

### How to Use? 
- Download the script, and give it executable permission using this command: `sudo chmod +x sub_recon.sh`
- Run the file using the following command: `./sub_recon.sh -u <DOMAIN_NAME>`
- To enumerate a whole scope at once, pass a file of in-scope domains with `-L`: `./sub_recon.sh -L scope.txt` (one domain per line; blank lines and `#comments` are ignored). The tool runs recon on each domain in turn and saves a separate output file for every one.
- A file named after the target (e.g. `tesla_com.txt`) would be created containing all the results found through automation. <br>Tools used: [`Subfinder`](https://github.com/projectdiscovery/subfinder), [`Assetfinder`](https://github.com/tomnomnom/assetfinder) & [`Sublist3r`](https://github.com/aboul3la/Sublist3r).
- Down below, you could find out some passive resources listed for other sources. This was done to ensure that the user is able to directly access the needed list with the minimum amount of headache.

> You can use this script to facilitate your own projects. This is the permission that this script is open to public.
---
- Fix_1.0: Added a check to detect the presence of the required tools on the User's system, and install them if unavailable.<br>This check is only performed once, when the script is run for the first time and is then skipped-over for better performance. Delete the `./.sub-recon_ran_already` file in the directory where the script was run initially to re-enable the check.<br>
- Fix_1.2: Added a Banner and Some visual Loading bars. Also added a flag_script for testing purposes. It would be excluded later.<br>
- Fix_1.3: Stripped the URL so that the output files are separated. Ex:-<br> 
> "https[:]//tesla.com" --> "tesla_com.txt"<br>
> "https[:]//tesla.net" --> "tesla_net.txt"
- Fix_1.4: Added the `-L` flag to pass a file of in-scope domains (one per line; blank lines and `#comments` are skipped). The tool loops over every domain in the list and saves a separate `<domain>.txt` for each.
