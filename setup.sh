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
  read -p "File (run.sh) already exists. Overwrite? [Y/n] " overwrite
  validate_y_no "$overwrite"
  if [ "${overwrite,,}" == "n" ]; then
    echo "Exiting..."
    exit 0
  fi
fi

echo "#!/usr/bin/bash" >$run_script
echo "cd $ROOT" >>$run_script
echo "mkdir -p output/tmp" >>$run_script
echo "cd output/tmp" >>$run_script
echo "rm -rf *" >> $run_script

# Building the wget command
wget_command="wget --adjust-extension --domains ${domain} --no-parent "
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
chmod +x $run_script

# Zip and compress the output
echo "tar -zcf ${filename} ${domain}" >>$run_script 

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
  # At this point, the contents of the tmp directory is the actual local
  # download, move that to the output directory.
  echo "mv ${filename} ../." >>$run_script
  echo "cd .." >>$run_script
  echo "rm -rf tmp" >>$run_script
  exit 0
fi

# Cloud backup
# Collect cloud storage details.
read -p 'Cloud backup platform [aws, azure, google]: ' cloud_platform
if [ "${cloud_platform,,}" != "aws" ] && [ "${cloud_platform,,}" != "azure" ] && [ "${cloud_platform,,}" != "google" ]; then
  echo "Invalid input. Please enter aws, azure, or google."
  exit 1
fi
if [ "${cloud_platform,,}" == 'azure' ]; then
  read -p 'Cloud account name: ' cloud_bucket
else 
  read -p 'Cloud backup bucket: ' cloud_bucket
fi
read -p 'Cloud backup directory: ' cloud_dir

if [ -z "${cloud_dir}" ]; then
  cloud_filepath="${filename}"
else
  cloud_filepath="${cloud_dir}/${filename}"
fi


# Update script to upload to cloud
case "${cloud_platform,,}" in
  aws)
    echo "aws s3 cp ${filename} s3://${cloud_bucket}/${cloud_filepath}" >>$run_script
    ;;
  azure)
    echo "az storage blob upload-batch --destination ${cloud_filepath} --source ${filename} --account-name ${cloud_bucket}" >>$run_script
    ;;
  google)
    echo "gsutil cp ${filename} gs://${cloud_bucket}/${cloud_filepath}" >>$run_script
    ;;
  *)
    echo "Invalid input. Please enter aws, azure, or google."
    exit 1
    ;;
esac

# Check if the backup was successful, if it was move the tmp directory,
# otherwise, retain the tmp directory and exit.
echo 'if [ $? -ne 0 ]; then' >>$run_script
echo "  echo 'Backup failed. Local backup will be retained in output/tmp.'" >>$run_script
echo "  exit 1" >>$run_script
echo "fi" >>$run_script

# If the backup passes, then we can safely remove the tmp directory.
echo "cd ${ROOT}" >>$run_script
echo "rm -rf output/tmp" >>$run_script
