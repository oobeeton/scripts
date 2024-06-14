import pandas as pd

# Define the checklist data
checklist_data = {
    "Function/Service": [
        "Storage", "Backups", "Internet Connectivity", "Email Systems", 
        "Active Directory", "VMware Environment", "Citrix Environment", 
        "Network Infrastructure", "Ticketing System", "Microsoft Cloud Systems", 
        "Security and Compliance", "Additional Observations and Recommendations"
    ],
    "Status": [""] * 12,  # Empty column for status entries
    "Checked By": [""] * 12,  # Empty column for initials/names of the checker
    "Notes/Findings": [""] * 12,  # Empty column for notes and findings
    "Recommendations/Actions Needed": [""] * 12  # Empty column for recommendations/actions
}

# Create a DataFrame
checklist_df = pd.DataFrame(checklist_data)

# Save to an Excel file
file_path = "/mnt/data/IT_Daily_Checklist.xlsx"
checklist_df.to_excel(file_path, index=False)

file_path
