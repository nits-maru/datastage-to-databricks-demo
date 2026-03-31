# test_transform_job.py
# pytest runs these automatically in CI

import pytest
from pyspark.sql import SparkSession
from src.transform_job import transform_orders


@pytest.fixture(scope="session")
def spark():
    """Spin up a local Spark session just for testing."""
    return (
        SparkSession.builder
        .master("local[1]")
        .appName("test_session")
        .getOrCreate()
    )


def test_filters_inactive_customers(spark):
    """Only active customers should pass through."""
    data = [
        (1, 101, "active",   500.0),
        (2, 102, "inactive", 300.0),
        (3, 103, "active",   200.0),
    ]
    df = spark.createDataFrame(data, ["customer_id", "order_id", "status", "order_total"])
    result = transform_orders(df)
    assert result.count() == 2


def test_tax_calculation(spark):
    """Order total should be multiplied by 1.18."""
    data = [(1, 101, "active", 100.0)]
    df = spark.createDataFrame(data, ["customer_id", "order_id", "status", "order_total"])
    result = transform_orders(df)
    row = result.collect()[0]
    assert abs(row["order_total_with_tax"] - 118.0) < 0.01


def test_output_columns(spark):
    """Output must have exactly these columns."""
    data = [(1, 101, "active", 100.0)]
    df = spark.createDataFrame(data, ["customer_id", "order_id", "status", "order_total"])
    result = transform_orders(df)
    assert set(result.columns) == {
        "customer_id", "order_id", "order_total_with_tax", "processed_date"
    }
