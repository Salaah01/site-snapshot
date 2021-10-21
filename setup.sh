#!/usr/bin/bash
# This script is used to create a bespoke script that would be used for backing
# up a site.

validate_y_no() {
  if [ "${1,,}" != "y" ] && [ "${1,,}" != "n" ]; then
    echo "Invalid input. Please enter y or n."
    exit 1
  fi
}

ROOT=$(dirname $BASH_SOURCE[0])

# Read args
read -p 'Domain: ' domain
read -p 'Recursive backup? [Y/n] (default Y) ' recursive
if [ -z "${recursive}" ]; then
  recursive="y"
fi
validate_y_no "$recursive"
read -p 'Download assets? [Y/n] (default Y) ' download_assets
if [ -z "${download_assets}" ]; then
  download_assets="y"
fi
validate_y_no "$download_assets"
read -p 'Download necessary offsite assets? [Y/n] (default Y) ' download_offsite_assets
if [ -z "${download_offsite_assets}" ]; then
  download_offsite_assets="y"
fi
validate_y_no "$download_offsite_assets"
read -p 'Convert links? [Y/n] (default Y) ' convert_links
if [ -z "${convert_links}" ]; then
  convert_links="y"
fi
validate_y_no "$convert_links"

filename=$domain-$(date +%F_%H-%M).tar.gz
read -p "File name [${filename}]" custom_filename

if [ -z "$custom_filename" ]; then
  filename=$domain-$(date +%F_%H-%M).tar.gz
fi

# Create run script
run_script="$ROOT/run.sh"

if [ -f "$run_script" ]; then
  read -p "File already exists. Overwrite? [Y/n] " overwrite
  validate_y_no "$overwrite"
  if [ "${overwrite,,}" == "n" ]; then
    echo "Exiting..."
    exit 0
  fi
fi

echo "!#/usr/bin/bash" >$run_script
echo "cd $ROOT" >>$run_script
echo "mkdir -p output/tmp" >>$run_script
echo "cd output/tmp" >>$run_script

# Building the wget command
wget_command="wget --adjust-extension domains ${domain} --no-parent "
if [ $recursive == 'y' ]; then
  wget_command="${wget_command} --recursive "
fi
if [ $download_assets == 'y' ]; then
  wget_command="${wget_command} --page-requisites "
fi
if [ $download_offsite_assets == 'y' ]; then
  wget_command="${wget_command} --span-hosts "
fi
if [ $convert_links == 'y' ]; then
  wget_command="${wget_command} --convert-links "
fi

echo "${wget_command} ${domain}" >>$run_script

echo "Local/cloud backup?"
echo "Supported cloud platforms: AWS, Azure, Google Cloud"
read -p '[local (default) /cloud] ' backup_type
if [ -z "$backup_type" ]; then
  backup_type="local"
fi
if [ "$backup_type" != "local" ] && [ "$backup_type" != "cloud" ]; then
  echo "Invalid input. Please enter local or cloud."
  exit 1
fi

if [ "$backup_type" == "local" ]; then
  read -p 'Local backup directory: ' backup_dir
else
  read -p 'Cloud backup platform: ' cloud_platform
  read -p 'Cloud backup bucket: ' cloud_bucket
  read -p 'Cloud backup directory: ' cloud_dir
fi
