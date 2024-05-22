#!/bin/bash

# Behavior:
# If a key is present in .env but not in .env.sample, it should be removed from .env.
# If a key is present in .env.sample but not in .env, it should be added to .env.
# If a key is present in both, and the value in .env.sample is non-empty, the value in .env should be updated.
# If a key is present in both, and the value in .env.sample is empty, the value in .env should be retained.

set -o pipefail  # Exit on pipe command errors

# Function to update .env file with .env.sample
update_env() {
    local env_path=$1
    local env_sample_path=$2
    local env_bak=$(mktemp)
    local env_new=$(mktemp)

    cp "$env_path" "$env_bak"  # backup original .env file

    # Process lines in .env.sample
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^#.*$ || $line == "" ]]; then  # if comment or empty line
            echo "$line" >> "$env_new"
        else
            key=$(echo "$line" | cut -d '=' -f 1)  # extract the key
            value_sample=$(echo "$line" | cut -d '=' -f 2-)  # extract the value from sample

            # search for the key in .env file
            value_env=$(grep -E "^${key}=" "$env_bak" | cut -d '=' -f 2-)
            if [[ -n "$value_env" && -n "$value_sample" ]]; then
                echo "$key=$value_sample" >> "$env_new"  # use updated value from .env.sample
            elif [[ -n "$value_env" ]]; then
                echo "$key=$value_env" >> "$env_new"  # use value from .env if key exists and sample value is empty
            else
                echo "$line" >> "$env_new"  # use default value from .env.sample
            fi
        fi
    done < "$env_sample_path"

    mv "$env_new" "$env_path"  # replace original .env file with the new one
}

update_env ".env" ".env.sample"
