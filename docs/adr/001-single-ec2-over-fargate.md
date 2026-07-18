# ADR 001: Single EC2 instance instead of Fargate/ALB for v1 hosting

**Status:** accepted (2026-07-15)

**Context:** I'm building a small portfolio project. Main goals are learning about new technology, bolstering my CV and proving my skills. Stability and availability are secondary. Choices were: 1) Fargate + ALB. Go-to AWS solution for modern web apps. 30-45$ before any users show up. 2) Single EC2 instance. More babysitting and probably not feasible if lots of users started showing up. Free in the first 6 months and cheap (10$/month) afterwards. 3) AWS App runner. AWS's one-click solution. 4) Render/Koyeb. Free but project goes idle, taking 30-60s to wake up when users visit. 

**Decision:** I chose EC2 because it's cheap, always-on, and hands-on IaaS — infrastructure I define and operate myself in Terraform, which is precisely the evidence this project exists to produce. I'm purposely going for the weakest "high availability" option here: cost is more important than availability at the moment.

**Rejected:** 

- Fargate: Too expensive. Revisit when real users arrive. Migration is cheap because the image, ECR, and OIDC pipeline carry over; only the compute swaps.
- App runner: No terraform surface to speak of, making it a bad fit for a CV project.
- Render/Koyeb: While availability isn't high on the priority list, I do want something that's at least always-on.
