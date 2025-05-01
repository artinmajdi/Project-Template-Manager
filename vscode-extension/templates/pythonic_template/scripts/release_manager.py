#!/usr/bin/env python3

import re
import subprocess
import sys
import os
from dotenv import load_dotenv
load_dotenv()
import requests


def get_latest_version():
    """
    Retrieves the latest git tag that follows semantic versioning (vX.Y.Z).
    If no tag exists, returns 'v0.0.0'.
    """
    try:
        result = subprocess.run(["git", "tag"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        tags = result.stdout.strip().splitlines()
        version_tags = []
        regex = re.compile(r'^v(\d+)\.(\d+)\.(\d+)$')
        for tag in tags:
            m = regex.match(tag)
            if m:
                major, minor, patch = map(int, m.groups())
                version_tags.append((major, minor, patch, tag))
        if not version_tags:
            return "v0.0.0"
        # Sort and return the highest version
        version_tags.sort(key=lambda x: (x[0], x[1], x[2]))
        return version_tags[-1][3]
    except subprocess.CalledProcessError:
        return "v0.0.0"


def bump_version(latest_version, bump_type):
    """
    Bumps the version based on the provided bump type: 'major', 'minor', or 'patch'.
    """
    regex = re.compile(r'^v(\d+)\.(\d+)\.(\d+)$')
    m = regex.match(latest_version)
    if not m:
        print("Latest version doesn't follow semantic versioning. Aborting.")
        sys.exit(1)
    major, minor, patch = map(int, m.groups())
    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'patch':
        patch += 1
    else:
        print("Invalid bump type specified.")
        sys.exit(1)
    return f"v{major}.{minor}.{patch}"


def create_github_release(version):
    """
    Creates a new release in GitHub using the API.
    Checks for GitHub credentials in .pypirc file first, then falls back to environment variables.
    """
    # Try to get token from .pypirc file first
    token = None
    try:
        # Get the project root directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        pypirc_path = os.path.join(project_root, '.pypirc')
        
        if os.path.exists(pypirc_path):
            print("Found .pypirc file, checking for GitHub credentials...")
            with open(pypirc_path, 'r') as f:
                pypirc_content = f.read()
                
            # Extract GitHub token from .pypirc
            github_section = re.search(r'\[github\](.*?)(?=\[|$)', pypirc_content, re.DOTALL)
            if github_section:
                token_match = re.search(r'password\s*=\s*(.*)', github_section.group(1))
                if token_match:
                    token = token_match.group(1).strip()
                    print("Found GitHub token in .pypirc file.")
    except Exception as e:
        print(f"Error reading .pypirc file: {e}")
    
    # If not found in .pypirc, check environment variables
    if not token or token.strip() == "":
        token = os.environ.get('GITHUB_TOKEN') or os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_PAT')
        
    if not token or token.strip() == "":
        print("No GitHub token found in .pypirc or environment variables. Skipping GitHub release creation.")
        return

    # Get repository info from remote URL
    try:
        result = subprocess.run(["git", "config", "--get", "remote.origin.url"], stdout=subprocess.PIPE, text=True, check=True)
    except subprocess.CalledProcessError:
        print("Failed to get remote URL from git config. Skipping GitHub release creation.")
        return

    repo_url = result.stdout.strip()
    owner = None
    repo = None
    if repo_url.startswith("git@github.com:"):
        m = re.match(r'git@github.com:(.*)/(.*)\.git', repo_url)
        if m:
            owner, repo = m.groups()
    elif repo_url.startswith("https://github.com/"):
        m = re.match(r'https://github.com/(.*)/(.*)\.git', repo_url)
        if m:
            owner, repo = m.groups()
    if not owner or not repo:
        print("Could not parse repository information from remote URL.")
        return

    release_url = f"https://api.github.com/repos/{owner}/{repo}/releases"
    payload = {
        "tag_name": version,
        "name": f"Release {version}",
        "body": "Release created by release_manager script.",
        "draft": False,
        "prerelease": False
    }
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    response = requests.post(release_url, json=payload, headers=headers)
    if response.status_code == 201:
        print(f"GitHub release created for {version}")
    else:
        print(f"Failed to create GitHub release: {response.status_code} {response.text}")


def create_new_release(version):
    """
    Creates a new annotated git tag for the release, pushes it to origin,
    and then creates a GitHub release.
    """
    tagline = f"Release {version}: New release"
    try:
        subprocess.run(["git", "tag", "-a", version, "-m", tagline], check=True)
        subprocess.run(["git", "push", "origin", version], check=True)
        print(f"Successfully created and pushed tag {version}")
        create_github_release(version)
    except subprocess.CalledProcessError as e:
        print("Error creating or pushing the tag:", e)
        sys.exit(1)


def main():
    latest = get_latest_version()
    print(f"Latest version is: {latest}")
    print("What type of release bump would you like to create?")
    print("Options: major, minor, patch, or custom")
    bump = input("Enter your choice: ").strip().lower()
    if bump == "custom":
        custom_version = input("Enter the custom version tag (e.g., v2.0.0): ").strip()
        new_version = custom_version
    elif bump in ["major", "minor", "patch"]:
        new_version = bump_version(latest, bump)
    else:
        print("No valid bump type selected. Exiting.")
        sys.exit(0)

    confirm = input(f"Do you want to create a new release {new_version}? (y/N): ").strip().lower()
    if confirm in ["y", "yes"]:
        create_new_release(new_version)
    else:
        print("No release created.")


if __name__ == '__main__':
    main()
