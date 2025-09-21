#!/bin/bash

# Change to the required directory
cd amazon-eks-ami/

# Create backup of original files
cp templates/shared/provisioners/generate-version-info.sh templates/shared/provisioners/generate-version-info.sh.backup
cp templates/shared/runtime/bin/cache-pause-container templates/shared/runtime/bin/cache-pause-container.backup
cp templates/al2023/variables-default.json templates/al2023/variables-default.json.backup
cp templates/al2023/provisioners/cache-pause-container.sh templates/al2023/provisioners/cache-pause-container.sh.backup
cp templates/al2023/template.json templates/al2023/template.json.backup
cp templates/al2023/provisioners/install-worker.sh templates/al2023/provisioners/install-worker.sh.backup

# Reset files from backups before applying changes
cp templates/shared/provisioners/generate-version-info.sh.backup templates/shared/provisioners/generate-version-info.sh
cp templates/shared/runtime/bin/cache-pause-container.backup templates/shared/runtime/bin/cache-pause-container
cp templates/al2023/variables-default.json.backup templates/al2023/variables-default.json
cp templates/al2023/provisioners/cache-pause-container.sh.backup templates/al2023/provisioners/cache-pause-container.sh
cp templates/al2023/provisioners/install-worker.sh.backup templates/al2023/provisioners/install-worker.sh

# Function to apply sed commands based on OS
apply_sed_commands() {
    OS=$(uname)
    if [ "$OS" = "Darwin" ]; then
        # Mac OS X commands
        echo "Applying changes for MacOS..."
        sed -i '' "s/chmod +x \$binary/chmod 755 \$binary/g" templates/al2023/provisioners/install-worker.sh
        sed -i '' 's#aws --version#sudo /bin//aws --version#g' templates/shared/provisioners/generate-version-info.sh
        sed -i '' 's#aws #sudo /bin//aws #g' templates/shared/runtime/bin/cache-pause-container
        sed -i '' 's#/tmp#/home/ec2-user#g' templates/al2023/variables-default.json
        sed -i '' 's#cache-pause-container#sudo cache-pause-container#g' templates/al2023/provisioners/cache-pause-container.sh
    else
        # Linux commands
        echo "Applying changes for Linux..."
        sed -i "s/chmod +x \$binary/chmod 755 \$binary/g" templates/al2023/provisioners/install-worker.sh
        sed -i 's#aws --version#sudo /bin//aws --version#g' templates/shared/provisioners/generate-version-info.sh
        sed -i 's#aws #sudo /bin//aws #g' templates/shared/runtime/bin/cache-pause-container
        sed -i 's#/tmp#/home/ec2-user#g' templates/al2023/variables-default.json
        sed -i 's#cache-pause-container#sudo cache-pause-container#g' templates/al2023/provisioners/cache-pause-container.sh
    fi
}

# First apply the sed commands
apply_sed_commands

# Then do the awk processing
awk -v q='"' '
BEGIN { 
    in_provisioner = 0
    shell_type = 0
    remote_folder_found = 0
    output = ""
}
{
    # Insert the new block after the EFA installation script
    if ($0 ~ /install-efa.sh/) {
        output = output $0 "\n"
        while (getline && $0 !~ /^    }/) {
            output = output $0 "\n"
        }
        output = output "    },\n"
        output = output "    {\n"
        output = output "      " q "type" q ": " q "shell" q ",\n"
        output = output "      " q "remote_folder" q ": " q "{{ user `remote_folder`}}" q ",\n"
        output = output "      " q "inline" q ": [\n"
        output = output "          " q "# Given SELINUX=enforcing on the base AMI CIS Amazon Linux 2023 Benchmark - Level 2" q ",\n"
        output = output "          " q "# Fixing SELinux-related permission issues where a binary isn'\''t executing due to incorrect context" q ",\n"
        output = output "          " q "sudo chcon -t bin_t /usr/bin/nodeadm" q ",\n"
        output = output "          " q "sudo chcon -t bin_t /usr/bin/kubelet" q ",\n"
        output = output "          " q "# Until nftables is supported on EKS we recommend disabling it https://github.com/aws/containers-roadmap/issues/2313" q ",\n"
        output = output "          " q "sudo yum remove nftables -y" q "\n"
        output = output "      ]\n"
        output = output "    },\n"
        next
    }

    if ($0 ~ /"provisioners"/) in_provisioner = 1
    
    if (in_provisioner) {
        if ($0 ~ /"type": "shell"/) {
            shell_type = 1
            remote_folder_found = 0
            indent = length($0) - length(ltrim($0))
        }
        if (shell_type && $0 ~ /"remote_folder"/) {
            remote_folder_found = 1
        }
        if (shell_type && $0 ~ /("inline"|"script":)/ && !remote_folder_found) {
            spaces = sprintf("%*s", indent, "")
            output = output spaces "\"remote_folder\": \"{{ user `remote_folder`}}\",\n" $0 "\n"
            shell_type = 0
            next
        }
    }
    
    if ($0 ~ /}/) {
        shell_type = 0
    }
    
    output = output $0 "\n"
}
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
END {
    printf "%s", output
}' templates/al2023/template.json > templates/al2023/template.json.new

# Verify changes
echo "Verifying changes..."
echo "Checking modifications:"
echo "1. generate-version-info.sh:"
grep "aws --version" templates/shared/provisioners/generate-version-info.sh
echo "2. cache-pause-container:"
grep "aws " templates/shared/runtime/bin/cache-pause-container
echo "3. variables-default.json:"
grep "/home" templates/al2023/variables-default.json
echo "4. cache-pause-container.sh:"
grep "sudo cache-pause-container" templates/al2023/provisioners/cache-pause-container.sh
echo "5. install-worker.sh:"
grep "chmod" templates/al2023/provisioners/install-worker.sh

# Check if the new template.json is valid
if command -v jq >/dev/null 2>&1; then
    if jq empty templates/al2023/template.json.new >/dev/null 2>&1; then
        mv templates/al2023/template.json.new templates/al2023/template.json
        echo "Successfully updated template.json"
    else
        echo "Error: Generated file is not valid JSON"
        mv templates/al2023/template.json.backup templates/al2023/template.json
        rm templates/al2023/template.json.new
        exit 1
    fi
else
    mv templates/al2023/template.json.new templates/al2023/template.json
    echo "Warning: jq not installed, couldn't validate JSON. File updated anyway."
fi

# If something went wrong, restore from backups
if [ $? -ne 0 ]; then
    echo "Error detected, restoring from backups..."
    for file in templates/shared/provisioners/generate-version-info.sh \
                templates/shared/runtime/bin/cache-pause-container \
                templates/al2023/variables-default.json \
                templates/al2023/provisioners/cache-pause-container.sh \
                templates/al2023/template.json \
                templates/al2023/provisioners/install-worker.sh; do
        mv "${file}.backup" "$file"
    done
    exit 1
fi

# Clean up backups if everything succeeded
rm templates/shared/provisioners/generate-version-info.sh.backup
rm templates/shared/runtime/bin/cache-pause-container.backup
rm templates/al2023/variables-default.json.backup
rm templates/al2023/provisioners/cache-pause-container.sh.backup
rm templates/al2023/template.json.backup
rm templates/al2023/provisioners/install-worker.sh.backup

echo "Script completed successfully!"