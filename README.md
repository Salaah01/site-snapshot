# Site Snapshot
This script will create you a shell script which when run will be able to:
* Take a live snapshot of your site recursively
* Download assets (css,js,images,etc)
* Allow you to convert the links to local links thus allowing you to run the site locally.
* Store locally or upload to the cloud (supports AWS, Microsoft Azure, Google Cloud Platform).

From there, you can either run the script as is or amend the script, making your own additions and changes.

Finally, add the script to a cron job if you wish and there you have it, your own script to take snapshots of websites.

## How to Use
```bash
./setup.sh
```
Answer the on screen questions to generate your shell script.

## Be Responsible
This script has the capability to scrape an entire site. Before running the outputted script, make sure that you have the correct permissions to do so as this likely may be violating the site's terms and conditions.
