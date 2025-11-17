#!/usr/bin/env python3
"""
Validate buildspec.yml files for CodeBuild compatibility
Checks for common issues that cause YAML_FILE_ERROR
"""

import sys
import yaml
from pathlib import Path


def validate_buildspec(file_path):
    """Validate a buildspec file structure"""
    print(f"\n{'='*60}")
    print(f"Validating: {file_path}")
    print(f"{'='*60}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = yaml.safe_load(f)
        
        # Check required top-level keys
        if 'version' not in content:
            print("❌ ERROR: Missing 'version' key")
            return False
        
        if 'phases' not in content:
            print("❌ ERROR: Missing 'phases' key")
            return False
        
        # Validate phases structure
        phases = content['phases']
        if not isinstance(phases, dict):
            print(f"❌ ERROR: 'phases' must be a dictionary, got {type(phases)}")
            return False
        
        # Check each phase
        for phase_name, phase_content in phases.items():
            print(f"\n  Phase: {phase_name}")
            
            if not isinstance(phase_content, dict):
                print(f"    ❌ ERROR: Phase '{phase_name}' must be a dictionary")
                return False
            
            # Check commands if present
            if 'commands' in phase_content:
                commands = phase_content['commands']
                if not isinstance(commands, list):
                    print(f"    ❌ ERROR: 'commands' must be a list, got {type(commands)}")
                    return False
                
                # Validate each command is a string
                for idx, cmd in enumerate(commands):
                    if not isinstance(cmd, str):
                        print(f"    ❌ ERROR: Command[{idx}] must be a string, got {type(cmd)}")
                        print(f"       Value: {cmd}")
                        return False
                    print(f"    ✅ Command[{idx}]: {cmd[:60]}{'...' if len(cmd) > 60 else ''}")
        
        # Check artifacts if present
        if 'artifacts' in content:
            artifacts = content['artifacts']
            if not isinstance(artifacts, dict):
                print(f"\n❌ ERROR: 'artifacts' must be a dictionary, got {type(artifacts)}")
                return False
            
            if 'files' in artifacts:
                files = artifacts['files']
                if not isinstance(files, list):
                    print(f"❌ ERROR: 'artifacts.files' must be a list, got {type(files)}")
                    return False
                print(f"\n✅ Artifacts: {len(files)} file patterns")
        
        print(f"\n{'='*60}")
        print(f"✅ VALID: {file_path}")
        print(f"{'='*60}")
        return True
        
    except yaml.YAMLError as e:
        print(f"❌ YAML Parse Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Validation Error: {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate-buildspec.py <buildspec-file> [<buildspec-file2> ...]")
        sys.exit(1)
    
    all_valid = True
    for file_path in sys.argv[1:]:
        path = Path(file_path)
        if not path.exists():
            print(f"❌ File not found: {file_path}")
            all_valid = False
            continue
        
        if not validate_buildspec(file_path):
            all_valid = False
    
    if all_valid:
        print("\n✅ All buildspec files are valid!")
        sys.exit(0)
    else:
        print("\n❌ Some buildspec files have errors")
        sys.exit(1)


if __name__ == '__main__':
    main()
