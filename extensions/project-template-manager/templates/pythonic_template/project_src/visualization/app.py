"""
Project visualization module.

This module provides comprehensive functionality for visualizing the dataset.
"""

import logging
from typing import Optional
import streamlit as st

from project_src.io.data_loader import DataLoader
from project_src.configuration import params, Settings, ConfigManager, logger



class Dashboard:
	"""Enhanced dashboard for the clinical research dataset."""

	def __init__(self):
		"""Initialize the dashboard component."""
		self.data_loader: Optional[DataLoader] = None

		# Session state initialization
		if 'feature' not in st.session_state:
			st.session_state.feature = None


	def load_data(self):
		"""Load the dataset using the DataLoader."""

		# TO-DO: something is something here
		# Initialize the DataLoader
		logger.info("Initializing DataLoader...")
		self.data_loader = DataLoader()

		# Load the dataset
		self.data = self.data_loader.load_data()

	def run(self):
		"""Render the dashboard."""
		# Set page config
		logger.info("Setting up Streamlit page configuration...")

		# Set up the Streamlit page configuration
		st.set_page_config(
			page_title="Project Visualization",
			page_icon="🦵",
			layout="wide",
			initial_sidebar_state="expanded"
		)

		# Apply custom CSS
		self._apply_custom_css()

		# Display header
		self._render_header()

		# Sidebar navigation
		self._render_sidebar()

		self.load_data()

		# Get current page from session state
		current_page = st.session_state.get('current_page', 'Overview')

		# Render current page
		if current_page == 'Overview':
			# self._render_overview()
			pass
		elif current_page == 'page2':
			# self._render_page2()
			pass
		else:
			# self._render_page3()
			pass


if __name__ == "__main__":
	# Create and render the dashboard
	dashboard = Dashboard()
	dashboard.run()
