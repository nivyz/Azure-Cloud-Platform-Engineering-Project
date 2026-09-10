## Topic: Terraform project structure

### Question
Why do we separate dev, qa, and prod?
for independent configuration and Terraform state.
prevents a development change from accidentally affecting production.

### Key terms
- Module: reusable Terraform code
- State: Terraform’s record of managed resources
