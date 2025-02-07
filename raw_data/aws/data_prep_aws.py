import json

# File paths
latency_matrix_path = "aws_latency_matrix.txt"
json_path = "data.json"
updated_json_path = "updated_data.json"

# Read AWS latency matrix file
with open(latency_matrix_path, "r") as f:
    lines = [line.strip() for line in f if line.strip()]  # Remove empty lines

# Identify the separator and split data
separator_index = lines.index("---")
region_names = lines[1:separator_index]  # Skip "To \ From" header
latency_data = lines[separator_index + 1:]

# Extract only valid latency values (removing mistakenly included region names)
filtered_latency_values = [value for value in latency_data if value not in region_names]

# Ensure correct matrix size
expected_values = len(region_names) ** 2
filtered_latency_values = filtered_latency_values[:expected_values]  # Trim any extra values

# Convert cleaned latency values into a structured dictionary
aws_latency_matrix = {}
index = 0

for i, from_region in enumerate(region_names):
    aws_latency_matrix[from_region] = {}
    for j, to_region in enumerate(region_names):
        value = filtered_latency_values[index].replace("ms", "").strip()  # Remove 'ms' and convert to float
        aws_latency_matrix[from_region][to_region] = float(value)
        index += 1

# Load existing JSON file
with open(json_path, "r") as f:
    azure_json = json.load(f)

# Add AWS latency matrix without modifying other fields
azure_json["aws"]["latency_matrix"] = aws_latency_matrix

# Save the updated JSON file
with open(updated_json_path, "w") as f:
    json.dump(azure_json, f, indent=4)

print(f"Updated JSON file saved as {updated_json_path}")
