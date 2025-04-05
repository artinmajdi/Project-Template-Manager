"""
Project dashboard built with Streamlit.

This module provides a web-based dashboard for visualizing and interacting with the project.
It offers data exploration, model performance visualization, and prediction capabilities.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple, Union

# Third-party imports
import numpy as np
import pandas as pd
import streamlit as st

# Local imports
from src.data.data_loader import DataLoader
from src.utils.config import Config, get_config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@dataclass
class PageConfig:
    """Configuration parameters for Streamlit page setup."""
    title: str
    icon: str
    layout: str
    sidebar_state: str


class Dashboard:
    """
    Main dashboard application class.

    This class encapsulates the Streamlit dashboard functionality,
    providing methods for various visualization pages and components.
    """

    def __init__(self, config: Config):
        """
        Initialize the dashboard with configuration.

        Args:
            config: Application configuration object
        """
        self.config = config
        self.data_loader = DataLoader()

        # Setup page configuration
        self.page_config = PageConfig(
            title=config.get("streamlit.page.title", "Project Dashboard"),
            icon="📊",
            layout=config.get("streamlit.page.layout", "wide"),
            sidebar_state=config.get("streamlit.page.initial_sidebar_state", "expanded")
        )

        # Configure the Streamlit page
        st.set_page_config(
            page_title=self.page_config.title,
            page_icon=self.page_config.icon,
            layout=self.page_config.layout,
            initial_sidebar_state=self.page_config.sidebar_state
        )

        # Page navigation mapping
        self.pages: Dict[str, Callable[[], None]] = {
            "Data Explorer": self.render_data_explorer,
            "Model Performance": self.render_model_performance,
            "Predictions": self.render_predictions
        }

    def run(self) -> None:
        """Run the dashboard application."""
        self._render_header()
        self._render_navigation()

    def _render_header(self) -> None:
        """Render the dashboard header and description."""
        st.title("Project Dashboard")
        st.markdown("""
        This is a template dashboard for your data science project. Customize it to fit your needs.

        - Visualize data
        - Explore model results
        - Test predictions
        """)

    def _render_navigation(self) -> None:
        """Render the navigation sidebar and handle page selection."""
        st.sidebar.title("Options")

        # Page selection
        selected_page = st.sidebar.selectbox(
            "Select a page",
            list(self.pages.keys())
        )

        # Display the selected page
        page_renderer = self.pages.get(selected_page)
        if page_renderer:
            page_renderer()

    def render_data_explorer(self) -> None:
        """Render the data exploration page."""
        st.header("Data Explorer")

        # Data loading section
        data = self._render_data_upload_section()

        if data is not None:
            # Display the data
            self._render_data_table(data)

            # Display statistics
            self._render_data_statistics(data)

            # Display visualizations
            self._render_data_visualizations(data)

    def _render_data_upload_section(self) -> Optional[pd.DataFrame]:
        """
        Render the data upload section and return the loaded data.

        Returns:
            DataFrame with the loaded data or None if no data loaded
        """
        st.subheader("Upload your own data")
        uploaded_file = st.file_uploader("Choose a CSV file", type="csv")

        try:
            if uploaded_file is not None:
                # Load uploaded data
                data = pd.read_csv(uploaded_file)
                st.success(f"Loaded data with {data.shape[0]} rows and {data.shape[1]} columns.")
                return data
            else:
                # Create sample data if no file is uploaded
                st.info("Upload a CSV file or use this sample data.")
                return pd.DataFrame({
                    'Category': ['A', 'B', 'C', 'A', 'B', 'C'],
                    'Value1': [10, 20, 30, 40, 50, 60],
                    'Value2': [5, 10, 15, 20, 25, 30]
                })
        except Exception as e:
            st.error(f"Error loading data: {str(e)}")
            logger.error(f"Error loading data: {e}", exc_info=True)
            return None

    def _render_data_table(self, data: pd.DataFrame) -> None:
        """
        Render a table display of the data.

        Args:
            data: DataFrame to display
        """
        st.subheader("Raw Data")
        st.dataframe(data)

    def _render_data_statistics(self, data: pd.DataFrame) -> None:
        """
        Render statistical information about the data.

        Args:
            data: DataFrame to analyze
        """
        st.subheader("Data Statistics")
        st.write(data.describe())

    def _render_data_visualizations(self, data: pd.DataFrame) -> None:
        """
        Render interactive data visualizations.

        Args:
            data: DataFrame to visualize
        """
        st.subheader("Data Visualization")

        if data.shape[1] <= 1:
            st.warning("Need at least two columns for visualization.")
            return

        # Find numeric columns for visualization
        numeric_cols = data.select_dtypes(include=['float64', 'int64']).columns.tolist()

        if not numeric_cols:
            st.warning("No numeric columns found for visualization.")
            return

        # Column selection for visualization
        x_col = st.selectbox("Select X axis", numeric_cols)
        y_col = st.selectbox(
            "Select Y axis",
            [col for col in numeric_cols if col != x_col] or numeric_cols
        )

        # Chart type selection
        chart_type = st.selectbox(
            "Select chart type",
            ["Line Chart", "Bar Chart", "Scatter Plot"]
        )

        try:
            # Create the selected visualization
            if chart_type == "Line Chart":
                st.line_chart(data=data, x=x_col, y=y_col)
            elif chart_type == "Bar Chart":
                st.bar_chart(data=data, x=x_col, y=y_col)
            else:  # Scatter Plot
                st.scatter_chart(data=data, x=x_col, y=y_col)
        except Exception as e:
            st.error(f"Error creating chart: {str(e)}")
            logger.error(f"Visualization error: {e}", exc_info=True)

    def render_model_performance(self) -> None:
        """Render the model performance visualization page."""
        st.header("Model Performance")

        # Information about the page
        st.info("This is a template for displaying model performance metrics and visualizations.")

        # Display metrics
        self._render_performance_metrics()

        # Display confusion matrix
        self._render_confusion_matrix()

        # Display feature importance
        self._render_feature_importance()

    def _render_performance_metrics(self) -> None:
        """Render model performance metrics."""
        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric(label="Accuracy", value="0.92", delta="0.03")

        with col2:
            st.metric(label="Precision", value="0.88", delta="-0.01")

        with col3:
            st.metric(label="Recall", value="0.95", delta="0.04")

        with col4:
            st.metric(label="F1 Score", value="0.91", delta="0.02")

    def _render_confusion_matrix(self) -> None:
        """Render a confusion matrix visualization."""
        st.subheader("Confusion Matrix")

        # Example confusion matrix data
        confusion_matrix = pd.DataFrame(
            [[85, 10], [5, 100]],
            columns=["Predicted Negative", "Predicted Positive"],
            index=["Actual Negative", "Actual Positive"]
        )

        st.table(confusion_matrix)

    def _render_feature_importance(self) -> None:
        """Render feature importance visualization."""
        st.subheader("Feature Importance")

        # Example feature importance data
        feature_importance = pd.DataFrame({
            'Feature': ['Feature A', 'Feature B', 'Feature C', 'Feature D', 'Feature E'],
            'Importance': [0.35, 0.25, 0.2, 0.15, 0.05]
        })

        st.bar_chart(data=feature_importance, x='Feature', y='Importance')

    def render_predictions(self) -> None:
        """Render the model prediction interface page."""
        st.header("Make Predictions")

        st.info("This is a template for a prediction interface. Customize the inputs based on your model.")

        with st.form("prediction_form"):
            # Input form for predictions
            st.subheader("Input Values")

            # Example input fields
            feature1 = st.slider("Feature 1", min_value=0.0, max_value=10.0, value=5.0, step=0.1)
            feature2 = st.slider("Feature 2", min_value=0.0, max_value=10.0, value=5.0, step=0.1)
            feature3 = st.selectbox("Feature 3", options=["Option A", "Option B", "Option C"])

            # Submit button
            submitted = st.form_submit_button("Make Prediction")

        if submitted:
            # Process and display prediction results
            self._show_prediction_results(feature1, feature2, feature3)

    def _show_prediction_results(self, feature1: float, feature2: float, feature3: str) -> None:
        """
        Display prediction results based on input features.

        Args:
            feature1: First feature value
            feature2: Second feature value
            feature3: Third feature value (categorical)
        """
        st.subheader("Prediction Result")

        # This is where you would call your model for predictions
        # For the template, we'll just use a dummy prediction
        feature3_value = 5.0 if feature3 == "Option A" else 2.0
        predicted_value = (feature1 * 0.6) + (feature2 * 0.4) + feature3_value

        st.success(f"Predicted Value: {predicted_value:.2f}")

        # Explanation of prediction
        st.subheader("Prediction Explanation")
        st.write("This is a placeholder for model explanation or feature contribution visualization.")

        # Example visualization of prediction factors
        self._show_prediction_factors(feature1, feature2, feature3, feature3_value)

    def _show_prediction_factors(
        self,
        feature1: float,
        feature2: float,
        feature3: str,
        feature3_value: float
    ) -> None:
        """
        Display the contribution of each factor to the prediction.

        Args:
            feature1: First feature value
            feature2: Second feature value
            feature3: Third feature value (categorical)
            feature3_value: Numeric value associated with feature3
        """
        factors = pd.DataFrame({
            'Factor': ['Feature 1', 'Feature 2', 'Feature 3'],
            'Contribution': [
                feature1 * 0.6,
                feature2 * 0.4,
                feature3_value
            ]
        })

        st.bar_chart(data=factors, x='Factor', y='Contribution')


def main() -> None:
    """Main entry point for the dashboard application."""
    try:
        # Load configuration
        config = get_config()

        # Create and run dashboard
        dashboard = Dashboard(config)
        dashboard.run()
    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
        logger.error(f"Dashboard error: {e}", exc_info=True)


if __name__ == "__main__":
    main()
