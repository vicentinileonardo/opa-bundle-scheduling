import json

def sort_and_reorder_json(input_file, output_file, sort_field, field_order=None):
    """
    Sort JSON array by specified field, preserving all original fields.
    
    Args:
    - input_file: Path to input JSON file
    - output_file: Path to output JSON file
    - sort_field: Field to sort the array by
    - field_order: Optional list of preferred field order
    """
    # Read JSON file
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    # Sort the array
    sorted_data = sorted(data, key=lambda x: x.get(sort_field, ''))
    
    # Reorder fields if specified, while preserving all original fields
    if field_order:
        reordered_data = []
        for item in sorted_data:
            # Create new dict with specified field order first
            reordered_item = {}
            
            # Add specified fields in order
            for field in field_order:
                if field in item:
                    reordered_item[field] = item[field]
            
            # Add any remaining fields
            for field, value in item.items():
                if field not in reordered_item:
                    reordered_item[field] = value
            
            reordered_data.append(reordered_item)
        sorted_data = reordered_data
    
    # Write to output file
    with open(output_file, 'w') as f:
        json.dump(sorted_data, f, indent=4)
    
    print(f"Sorted JSON saved to {output_file}")


# Example usage
if __name__ == "__main__":
    # Sort by 'Name' field, reorder to put 'Name' first while keeping other fields
    sort_and_reorder_json(
        input_file='input.json', 
        output_file='sorted_output.json', 
        sort_field='Name',
        field_order=['Name', 'DisplayName']
    )
