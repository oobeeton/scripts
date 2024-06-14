import os
import xml.etree.ElementTree as ET
import pandas as pd

def parse_xml(file_path):
    """
    Parse an XML file and extract GPO settings.
    """
    tree = ET.parse(file_path)
    root = tree.getroot()
    gpo_settings = []

    # Navigate through the XML structure
    for extension_data in root.findall('.//ExtensionData'):
        extension_name = extension_data.find('Name').text if extension_data.find('Name') is not None else "Unknown"

        for extension in extension_data.findall('.//Extension'):
            xsi_type = extension.attrib.get('{http://www.w3.org/2001/XMLSchema-instance}type', '')
            if 'AuditSettings' in xsi_type:
                for setting in extension.findall('.//*'):
                    if setting.tag.endswith('AuditSetting'):
                        policy_target = setting.find('*[local-name()="PolicyTarget"]').text
                        subcategory_name = setting.find('*[local-name()="SubcategoryName"]').text
                        setting_value = setting.find('*[local-name()="SettingValue"]').text
                        gpo_settings.append((f"{policy_target}_{subcategory_name}", setting_value))
            elif 'RegistrySettings' in xsi_type:
                for policy in extension.findall('.//*'):
                    if policy.tag.endswith('Policy'):
                        policy_name = policy.find('*[local-name()="Name"]').text
                        state = policy.find('*[local-name()="State"]').text
                        explain = policy.find('*[local-name()="Explain"]').text if policy.find('*[local-name()="Explain"]') is not None else "No explanation provided"
                        gpo_settings.append((policy_name, f"{state} ({explain})"))

    return dict(gpo_settings)

def process_directory(directory_path):
    """
    Process all XML files in the specified directory and merge the results.
    """
    all_data = {}
    
    # Iterate through all XML files in the directory
    for filename in os.listdir(directory_path):
        if filename.endswith('.xml'):
            file_path = os.path.join(directory_path, filename)
            gpo_settings = parse_xml(file_path)
            
            # Merge results
            for setting_name, setting_value in gpo_settings.items():
                if setting_name not in all_data:
                    all_data[setting_name] = [setting_name, 'Description not provided']  # Placeholder for description
                all_data[setting_name].append(setting_value)
    
    return all_data

def main():
    directory_path = 'D:\\Scripts\\GPOreports'
    data = process_directory(directory_path)
    df = pd.DataFrame.from_dict(data, orient='index').transpose()

    # Save to Excel
    df.to_excel('gpo_settings.xlsx', index=False)

if __name__ == "__main__":
    main()
