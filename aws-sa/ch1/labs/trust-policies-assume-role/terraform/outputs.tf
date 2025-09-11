output "lab_summary" {
  description = "Summary of deployed resources for lab steps"
  value = {
    lab_name    = var.lab_name
    region      = var.aws_region
    account_id  = data.aws_caller_identity.current.account_id
  }
}

output "developer_user_arn" {
  description = "ARN of the developer IAM user"
  value       = aws_iam_user.developer.arn
}

output "developer_access_key_id" {
  description = "Access key ID for the developer user (use for CLI configuration)"
  value       = aws_iam_access_key.developer_key.id
}

output "developer_secret_access_key" {
  description = "Secret access key for the developer user (use for CLI configuration)"
  value       = aws_iam_access_key.developer_key.secret
  sensitive   = true
}

output "s3_access_role_arn" {
  description = "ARN of the S3 access role to assume"
  value       = aws_iam_role.s3_access_role.arn
}

output "target_bucket_name" {
  description = "Name of the S3 bucket to access after assuming role"
  value       = aws_s3_bucket.target_bucket.bucket
}

output "sample_file_key" {
  description = "Key of the sample file in the S3 bucket"
  value       = aws_s3_object.sample_file.key
}

output "external_id" {
  description = "External ID to use when assuming the role"
  value       = var.external_id
  sensitive   = true
}

output "assume_role_command" {
  description = "Sample AWS CLI command to assume the role"
  value = "aws sts assume-role --role-arn ${aws_iam_role.s3_access_role.arn} --role-session-name lab-session --external-id ${var.external_id}"
}

output "test_s3_commands" {
  description = "Sample S3 commands to test after assuming role"
  value = {
    list_buckets = "aws s3 ls"
    list_bucket_contents = "aws s3 ls s3://${aws_s3_bucket.target_bucket.bucket}/"
    download_sample_file = "aws s3 cp s3://${aws_s3_bucket.target_bucket.bucket}/${aws_s3_object.sample_file.key} ./downloaded-file.txt"
    upload_test_file = "echo 'Test upload' | aws s3 cp - s3://${aws_s3_bucket.target_bucket.bucket}/test-upload.txt"
  }
}
