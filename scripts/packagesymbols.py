#!/usr/bin/env python

# This script goes through the provided .xcarchive and generates the breakpad symbol file structure and symbols
# for both arm64/armv7 architectures. The resulting .zip can be directly uploaded to crash-stats for processing.

from __future__ import print_function

import argparse
import os
import subprocess
import sys
import zipfile

archs = ['arm64', 'armv7']

# Return the MachO full path from a .app/.framework path
def macho_path(path):
    return os.path.join(path, os.path.basename(path).split(".")[0])

# Get the path to the .dSYM file (Client.app.dSYM) for the given MachO binary (Client)
def get_dsym_path_for_macho(archive, macho_name): 
    try:
        stdout = subprocess.check_output(['find', archive, '-name', macho_name + '.*.dSYM'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding dSYM error: %s' % e)   
        return None

    return stdout.rstrip()

# Find all the dynamic frameworks inside the archive that we want symbolicated
def get_framework_paths(archive):
    try:
        stdout = subprocess.check_output(['find', archive, '-name', '*.framework'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding frameworks error: %s' % e)   
        return None

    return map(macho_path, stdout.splitlines())

# Find the app's executable name
def get_executable_path(archive):
    try:
        stdout = subprocess.check_output(['find', archive, '-name', '*.app'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding executable error: %s' % e)   
        return None

    return macho_path(stdout.rstrip())

def process_file(dump_syms, path, arch, dsym):
    try:
        stdout = subprocess.check_output([dump_syms, '-a', arch, '-g', dsym, path],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Error: %s' % e)
        return None, None, None
    bits = stdout.splitlines()[0].split(' ', 4)
    if len(bits) != 5:
        return None, None, None
    _, platform, cpu_arch, debug_id, debug_file = bits
    if debug_file.lower().endswith('.pdb'):
        sym_file = debug_file[:-4] + '.sym'
    else:
        sym_file = debug_file + '.sym'
    filename = os.path.join(debug_file, debug_id, sym_file)
    debug_filename = os.path.join(debug_file, debug_id, debug_file)
    return filename, stdout, debug_filename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dump_syms', help='Path to dump_syms binary')
    parser.add_argument('archive', help='Path to archive to get symbols from')
    parser.add_argument('--symbol-zip', default='symbols.zip',
                        help='Name of zip file to put dumped symbols in')
    # parser.add_argument('--dsym', help='dSYM info for the target MachO file to provide richer symbols')
    args = parser.parse_args()

    files = []
    framework_paths = get_framework_paths(args.archive) 
    if files != None:
      files.extend(framework_paths)
      executable_path = get_executable_path(args.archive)   

      if executable_path != None:
          files.append(executable_path)

    print(files)

    count = 0
    with zipfile.ZipFile(args.symbol_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
        for f in files:
            dsym = get_dsym_path_for_macho(args.archive, os.path.basename(f).split(".")[0])  
            for arch in archs:
                filename, contents, debug_filename = process_file(args.dump_syms, f, arch, dsym)
                if not (filename and contents):
                    print('Error dumping symbols')
                    sys.exit(1)
                zf.writestr(filename, contents)
                zf.write(f, debug_filename)
                count += 2
    print('Added %d files to %s' % (count, args.symbol_zip))

if __name__ == '__main__':
    main()

