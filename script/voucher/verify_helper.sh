#!/bin/bash

# Define the start and end versions
start_version="0.8.20"
end_version="0.8.25"

# Convert version to an array for easy iteration
start_arr=(${start_version//./ })
end_arr=(${end_version//./ })

# Loop through each version
for major in $(seq ${start_arr[0]} ${end_arr[0]}); do
  for minor in $(seq ${start_arr[1]} ${end_arr[1]}); do
    for patch in $(seq ${start_arr[2]} ${end_arr[2]}); do
      version="$major.$minor.$patch"
      echo "Running command for version $version"
      
      forge verify-contract 0xfb62695F550929b6630D7A395D8aB69605DbE230 \
        --watch \
        --chain 43114 \
        src/VoucherFactory.sol:VoucherFactory \
        --etherscan-api-key "" \
        --num-of-optimizations 200 \
        --compiler-version $version
    done
  done
done

