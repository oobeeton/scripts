import os
import shutil
from collections import defaultdict
import sys

def file_suffix(index):
    """Generates a suffix string based on the index."""
    return f".{index}" if index else ""

def get_file_info(path):
    """Retrieve file information needed for comparison."""
    try:
        stat = os.stat(path)
        return (os.path.basename(path), stat.st_size, stat.st_mtime)
    except FileNotFoundError:
        return None

def move_file(src, dest, is_duplicate=False):
    """Move file to its new destination, handling duplicates."""
    base, ext = os.path.splitext(dest)
    index = 0
    new_dest = dest
    while os.path.exists(new_dest):
        file_info = get_file_info(new_dest)
        src_info = get_file_info(src)
        if file_info == src_info:
            if is_duplicate:
                new_dest = f"{base}{file_suffix(index)}{ext}"
                index += 1
            else:
                # Identical file already exists, do not move.
                return
        else:
            new_dest = f"{base}{file_suffix(index)}{ext}"
            index += 1
    shutil.move(src, new_dest)

def organize_files(root_dir):
    """Organize files by their type and handle duplicates."""
    file_paths = defaultdict(list)
    duplicates_dir = os.path.join(root_dir, "duplicates")

    # Ensure the duplicates directory exists.
    os.makedirs(duplicates_dir, exist_ok=True)

    # Traverse the directory and collect all files.
    for subdir, dirs, files in os.walk(root_dir):
        for file in files:
            path = os.path.join(subdir, file)
            file_type = file.split('.')[-1]
            file_paths[file_type].append(path)

    # Move files to their respective directories and handle duplicates.
    for file_type, paths in file_paths.items():
        type_dir = os.path.join(root_dir, file_type)
        os.makedirs(type_dir, exist_ok=True)
        
        for path in paths:
            dest_dir = type_dir if get_file_info(path) not in [get_file_info(p) for p in paths if p != path] else duplicates_dir
            dest_path = os.path.join(dest_dir, os.path.basename(path))
            move_file(path, dest_path, is_duplicate=(dest_dir == duplicates_dir))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        directory_to_organize = sys.argv[1]
        print(f"Organizing files in {directory_to_organize}")
        organize_files(directory_to_organize)
    else:
        print("Please specify a directory path to organize.")
