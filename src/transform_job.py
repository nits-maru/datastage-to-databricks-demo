# transform_job.py
# Converted from DataStage: Customer_Order_Transform job

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def create_spark_session(app_name: str) -> SparkSession:
    """Create or get a Spark session."""
    return SparkSession.builder.appName(app_name).getOrCreate()


def transform_orders(df):
    """
    Core transformation logic.
    Original DataStage job: filtered active customers,
    calculated order totals with tax.
    """
    return (
        df.filter(F.col("status") == "active")
          .withColumn("order_total_with_tax", F.col("order_total") * 1.18)
          .withColumn("processed_date", F.current_timestamp())
          .select("customer_id", "order_id", "order_total_with_tax", "processed_date")
    )


def main():
    spark = create_spark_session("CustomerOrderTransform")
    print("Transform job ready. Waiting for input data path.")


if __name__ == "__main__":
    main()
