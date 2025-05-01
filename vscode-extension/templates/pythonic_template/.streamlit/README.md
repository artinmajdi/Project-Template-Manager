# Streamlit Deployment Guide

This directory contains configuration files for deploying the Wound EHR Analyzer application to Streamlit Cloud.

## Deployment Files

- `config.toml`: Main Streamlit configuration (theme, server settings)
- `runtime.py`: Python path configuration and environment setup
- `secrets.toml`: Template for secrets management (API keys, etc.)
- `requirements.txt`: Streamlit-specific dependencies
- `packages.txt`: System dependencies for Streamlit Cloud
- `deployment_config.toml`: Deployment configuration settings

## Deployment Steps

1. **Prepare your repository**
   - Ensure your main Streamlit app is at the root level (streamlit_app.py)
   - Verify all configuration files in the .streamlit directory are up to date

2. **Set up Streamlit Cloud**
   - Create an account on [Streamlit Cloud](https://streamlit.io/cloud)
   - Connect your GitHub repository
   - Select the main file to run (streamlit_app.py)

3. **Configure Secrets**
   - In the Streamlit Cloud dashboard, go to your app settings
   - Add the secrets from secrets.toml to the Streamlit Cloud secrets manager
   - Ensure all API keys and sensitive information are properly set

4. **Advanced Settings**
   - Set Python version to 3.12
   - Configure memory requirements if needed
   - Set up custom domain if desired

5. **Deploy**
   - Click "Deploy" in the Streamlit Cloud dashboard
   - Monitor the build logs for any issues

## Local Testing

Before deploying to Streamlit Cloud, test your app locally:

```bash
streamlit run streamlit_app.py
```

## Troubleshooting

- If you encounter import errors, check the runtime.py file and ensure paths are correctly set
- For dependency issues, verify requirements.txt includes all necessary packages
- For secrets issues, ensure all required secrets are properly configured in Streamlit Cloud

## Resources

- [Streamlit Cloud Documentation](https://docs.streamlit.io/streamlit-cloud)
- [Secrets Management](https://docs.streamlit.io/streamlit-cloud/get-started/deploy-an-app/connect-to-data-sources/secrets-management)
- [App Dependencies](https://docs.streamlit.io/streamlit-cloud/get-started/deploy-an-app/app-dependencies)
