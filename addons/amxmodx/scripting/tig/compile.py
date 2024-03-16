import os
import subprocess
import shelve

folder = os.getcwd()
output_file = "compile"

with shelve.open(output_file) as my_dict:

    for root, dirs, files in os.walk(folder):
        for file in files:
            if file.endswith(".sma"):
                path = os.path.join(root, file)
                modified_time = os.path.getmtime(path)
                if file not in my_dict or modified_time != my_dict[file]:
                    parent = os.path.dirname(folder)
                    name, ext = os.path.splitext(file)
                    cmd = f'\"{parent}/amxxpc\" {path} -i\"{parent}/include\" -i\"{folder}/include\" -o\"{folder}/compiled/{name}.amxx\"'
                    print("------------------------------")
                    print(f"Compiling {file}\n")
                    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                    print(result.stdout)
                    print(result.stderr)
                    if result.stdout.find("error") == -1:
                        my_dict[file] = modified_time

    my_dict.close()

print("Done!")