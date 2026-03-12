# Roboshop AWS Infrastructure

Terraform-based Infrastructure as Code for deploying the [RoboShop](https://github.com/roboshop-devops) e-commerce microservices application on AWS. The project provisions a full production-grade environment including networking, security, databases, load balancers, auto-scaling compute, SSL/TLS, and a CloudFront CDN.

<h1>Roboshop VM Architecture</h1>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>RoboShop AWS Architecture</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react/18.2.0/umd/react.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react-dom/18.2.0/umd/react-dom.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/babel-standalone/7.23.2/babel.min.js"></script>
<style>* { box-sizing: border-box; margin: 0; padding: 0; }</style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
const { useState } = React;

const services = {
  internet: { id: "internet", label: "Internet", icon: "🌐" },
  cdn: { id: "cdn", label: "CloudFront CDN", sub: "Geo-restriction · TLS · Caching", icon: "⚡" },
  frontendAlb: { id: "frontendAlb", label: "Frontend ALB", sub: "Public · HTTPS 443 · ACM cert", icon: "⚖️" },
  vpn: { id: "vpn", label: "OpenVPN", sub: "Ports 22/443/943/1194", icon: "🔒" },
  bastion: { id: "bastion", label: "Bastion Host", sub: "SSH jump · 50 GB gp3", icon: "🏠" },
  frontend: { id: "frontend", label: "Frontend", sub: "Nginx 1.24 · ASG · Node.js static", runtime: "nginx", icon: "🖥️" },
  backendAlb: { id: "backendAlb", label: "Backend ALB", sub: "Internal · HTTP 80 · Host-header routing", icon: "⚖️" },
  catalogue: { id: "catalogue", label: "Catalogue", sub: "Node.js · port 8080", runtime: "node", priority: 10, icon: "📦" },
  user: { id: "user", label: "User", sub: "Node.js · port 8080", runtime: "node", priority: 20, icon: "👤" },
  cart: { id: "cart", label: "Cart", sub: "Node.js · port 8080", runtime: "node", priority: 30, icon: "🛒" },
  shipping: { id: "shipping", label: "Shipping", sub: "Java/Maven · port 8080", runtime: "java", priority: 40, icon: "🚚" },
  payment: { id: "payment", label: "Payment", sub: "Python/uWSGI · port 8080", runtime: "python", priority: 50, icon: "💳" },
  mongodb: { id: "mongodb", label: "MongoDB", sub: "Port 27017", icon: "🍃" },
  redis: { id: "redis", label: "Redis 7", sub: "Port 6379", icon: "🔴" },
  mysql: { id: "mysql", label: "MySQL", sub: "Port 3306 · SSM password", icon: "🐬" },
  rabbitmq: { id: "rabbitmq", label: "RabbitMQ", sub: "Port 5672 · roboshop user", icon: "🐇" },
};

const connections = {
  internet: ["cdn", "vpn", "bastion"],
  cdn: ["frontendAlb"],
  frontendAlb: ["frontend"],
  frontend: ["backendAlb"],
  backendAlb: ["catalogue", "user", "cart", "shipping", "payment"],
  catalogue: ["mongodb"],
  user: ["mongodb", "redis"],
  cart: ["redis", "catalogue"],
  shipping: ["mysql", "cart"],
  payment: ["rabbitmq", "cart", "user"],
};

const runtimeColor = { node: "#68d391", python: "#f6ad55", java: "#fc8181", nginx: "#63b3ed" };

const details = {
  internet: { desc: "Public internet traffic", notes: [] },
  cdn: { desc: "AWS CloudFront distribution sits at the edge, terminating TLS with ACM certificate.", notes: ["Geo-restricted: US, CA, GB, DE, FR, IN, AU", "Default behaviour: caching disabled (dynamic content)", "/media/* path: caching enabled", "Price class PriceClass_200", "HTTPS-only viewer protocol"] },
  frontendAlb: { desc: "Internet-facing Application Load Balancer in public subnets.", notes: ["HTTPS 443 only", "ACM wildcard certificate attached", "Routes to Frontend ASG target group", "Security group allows 0.0.0.0/0 on 80 & 443"] },
  vpn: { desc: "OpenVPN EC2 instance for secure developer access to private resources.", notes: ["Ports: 22, 443, 943, 1194", "In public subnet", "Allows access to all private/database SGs"] },
  bastion: { desc: "Emergency SSH jump host for direct instance access.", notes: ["50 GB gp3 root volume", "IAM profile: EC2FORTERRAFORMADMIN", "Used to run Terraform operations", "Public subnet, SSH from 0.0.0.0/0"] },
  frontend: { desc: "Nginx serves static React files and reverse-proxies API calls to backend services.", notes: ["ASG: min 1, max 10, target 75% CPU", "Rolling instance refresh on AMI change", "Golden AMI bake via Ansible role", "Proxies /api/catalogue/, /api/user/, /api/cart/, /api/shipping/, /api/payment/"] },
  backendAlb: { desc: "Internal ALB routing requests by host-header to individual microservices.", notes: ["Internal only (not internet-facing)", "Private subnets", "Each service has a listener rule with unique priority", "Wildcard DNS: *.backend-dev.hellodevsecops.space"] },
  catalogue: { desc: "Manages product catalogue data. Node.js app backed by MongoDB.", notes: ["Ansible role: app-setup → nodejs → mongosh client → seed check → systemd", "Seeds master-data.js if DB doesn't exist", "ALB listener priority: 10", "ASG: min 1, max 10, 75% CPU target tracking"] },
  user: { desc: "Handles user accounts, authentication, and sessions.", notes: ["Node.js · Ansible: app-setup → nodejs → systemd", "Session data in Redis", "User profile data in MongoDB", "ALB listener priority: 20"] },
  cart: { desc: "Shopping cart service. Uses Redis for fast session storage.", notes: ["Node.js · Ansible: app-setup → nodejs → systemd", "Cart data in Redis", "Product lookups via Catalogue service", "ALB listener priority: 30"] },
  shipping: { desc: "Calculates shipping costs and city data. Java Spring Boot app.", notes: ["Java/Maven · Ansible: app-setup → maven → MySQL schema import → systemd", "Imports schema.sql, app-user.sql, master-data.sql on first run", "ALB listener priority: 40"] },
  payment: { desc: "Processes payments. Python app running under uWSGI.", notes: ["Python/uWSGI · runs as root (uWSGI requirement)", "Ansible: app-setup → python → systemd", "Talks to Cart, User, and RabbitMQ (AMQP)", "ALB listener priority: 50"] },
  mongodb: { desc: "MongoDB 7 for catalogue and user data.", notes: ["EC2 t3.micro, database subnet", "Bind address changed to 0.0.0.0 for VPC access", "DNS: mongodb-dev.hellodevsecops.space → private IP", "Accessible from: catalogue, user (port 27017)"] },
  redis: { desc: "Redis 7 for session and cart caching.", notes: ["EC2 t3.micro, database subnet", "Protected-mode disabled, bind 0.0.0.0", "DNS: redis-dev.hellodevsecops.space → private IP", "Accessible from: user, cart (port 6379)"] },
  mysql: { desc: "MySQL for shipping/city reference data.", notes: ["EC2 t3.micro, database subnet", "Root password fetched from AWS SSM Parameter Store", "IAM profile: ec2fetchssmparameter", "DNS: mysql-dev.hellodevsecops.space → private IP"] },
  rabbitmq: { desc: "RabbitMQ message broker for async payment processing.", notes: ["EC2 t3.micro, database subnet", "roboshop user: full perms on default vhost /", "DNS: rabbitmq-dev.hellodevsecops.space → private IP", "Accessible from: payment (port 5672)"] },
};

function App() {
  const [selected, setSelected] = useState(null);
  const sel = selected ? details[selected] : null;
  const selService = selected ? services[selected] : null;

  const ServiceBox = ({ id, style = {} }) => {
    const s = services[id];
    const isSelected = selected === id;
    const rt = s.runtime;
    return (
      <div
        onClick={() => setSelected(isSelected ? null : id)}
        style={{
          background: isSelected ? "rgba(99,179,237,0.18)" : "rgba(255,255,255,0.05)",
          border: `1.5px solid ${isSelected ? "#63b3ed" : "rgba(255,255,255,0.12)"}`,
          borderLeft: rt ? `3px solid ${runtimeColor[rt]}` : undefined,
          borderRadius: 8, padding: "8px 12px", cursor: "pointer",
          transition: "all 0.18s", minWidth: 130, ...style,
        }}
      >
        <div style={{ fontSize: 11, opacity: 0.5, marginBottom: 1 }}>{s.icon}</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: "#e2e8f0", letterSpacing: 0.2 }}>{s.label}</div>
        {s.sub && <div style={{ fontSize: 9.5, color: "#94a3b8", marginTop: 2, lineHeight: 1.3 }}>{s.sub}</div>}
        {s.runtime && <div style={{ fontSize: 9, marginTop: 4, display: "inline-block", padding: "1px 5px", borderRadius: 3, background: runtimeColor[s.runtime] + "22", color: runtimeColor[s.runtime], fontWeight: 600, letterSpacing: 0.5 }}>{s.runtime.toUpperCase()}</div>}
      </div>
    );
  };

  const Zone = ({ label, color, children, style = {} }) => (
    <div style={{ border: `1px dashed ${color}40`, borderRadius: 12, padding: "14px 16px 16px", position: "relative", ...style }}>
      <div style={{ position: "absolute", top: -10, left: 14, background: "#0f172a", padding: "0 8px", fontSize: 10, fontWeight: 700, letterSpacing: 1, color: color, textTransform: "uppercase" }}>{label}</div>
      {children}
    </div>
  );

  const Arrow = ({ label }) => (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, padding: "2px 0" }}>
      <div style={{ fontSize: 9, color: "#64748b", letterSpacing: 0.5 }}>{label}</div>
      <div style={{ color: "#475569", fontSize: 16, lineHeight: 1 }}>↓</div>
    </div>
  );

  return (
    <div style={{ minHeight: "100vh", background: "#0f172a", fontFamily: "'JetBrains Mono', 'Fira Code', monospace", color: "#e2e8f0", padding: "24px 20px" }}>
      <div style={{ textAlign: "center", marginBottom: 28 }}>
        <div style={{ fontSize: 11, letterSpacing: 3, color: "#475569", marginBottom: 6, textTransform: "uppercase" }}>Infrastructure Architecture</div>
        <div style={{ fontSize: 22, fontWeight: 800, color: "#f1f5f9", letterSpacing: -0.5 }}>RoboShop on AWS</div>
        <div style={{ fontSize: 11, color: "#64748b", marginTop: 4 }}>Terraform + Ansible · Golden AMI · Auto Scaling · CloudFront</div>
      </div>

      <div style={{ display: "flex", gap: 20, alignItems: "flex-start", maxWidth: 1100, margin: "0 auto" }}>
        <div style={{ flex: 1 }}>
          <div style={{ display: "flex", gap: 16, marginBottom: 12, alignItems: "center" }}>
            <div style={{ flex: 1, display: "flex", justifyContent: "center" }}><ServiceBox id="internet" style={{ textAlign: "center" }} /></div>
            <Zone label="Management Access" color="#a78bfa" style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <ServiceBox id="bastion" /><ServiceBox id="vpn" />
            </Zone>
          </div>
          <Arrow label="HTTPS" />
          <Zone label="Edge — CloudFront" color="#f6ad55" style={{ marginBottom: 12 }}>
            <div style={{ display: "flex", justifyContent: "center" }}><ServiceBox id="cdn" style={{ minWidth: 240, textAlign: "center" }} /></div>
          </Zone>
          <Arrow label="HTTPS · ACM" />
          <Zone label="Public Subnet · us-east-1a/b · 10.0.1-2.0/24" color="#68d391" style={{ marginBottom: 12 }}>
            <div style={{ display: "flex", justifyContent: "center" }}><ServiceBox id="frontendAlb" style={{ minWidth: 240, textAlign: "center" }} /></div>
          </Zone>
          <Arrow label="HTTP 80" />
          <Zone label="Private Subnet · 10.0.11-12.0/24" color="#63b3ed" style={{ marginBottom: 12 }}>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
              <ServiceBox id="frontend" style={{ minWidth: 260, textAlign: "center" }} />
              <Arrow label="/api/* proxy" />
              <ServiceBox id="backendAlb" style={{ minWidth: 260, textAlign: "center" }} />
              <div style={{ display: "flex", gap: 10, marginTop: 4, flexWrap: "wrap", justifyContent: "center" }}>
                {["catalogue","user","cart","shipping","payment"].map(id => <ServiceBox key={id} id={id} />)}
              </div>
            </div>
          </Zone>
          <div style={{ display: "flex", justifyContent: "center", gap: 40, marginBottom: 6 }}>
            {[["27017","catalogue+user"],["6379","user+cart"],["3306","shipping"],["5672","payment"]].map(([port,label]) => (
              <div key={port} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 1 }}>
                <div style={{ fontSize: 8.5, color: "#64748b" }}>{label}</div>
                <div style={{ color: "#475569", fontSize: 14 }}>↓</div>
                <div style={{ fontSize: 9, color: "#64748b" }}>:{port}</div>
              </div>
            ))}
          </div>
          <Zone label="Database Subnet · 10.0.21-22.0/24" color="#f687b3" style={{ marginTop: 4 }}>
            <div style={{ display: "flex", gap: 10, justifyContent: "center", flexWrap: "wrap" }}>
              {["mongodb","redis","mysql","rabbitmq"].map(id => <ServiceBox key={id} id={id} />)}
            </div>
          </Zone>
          <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
            <div style={{ flex: 1, border: "1px solid rgba(255,255,255,0.08)", borderRadius: 8, padding: "10px 14px", fontSize: 10, color: "#64748b" }}>
              <div style={{ color: "#94a3b8", fontWeight: 700, marginBottom: 5 }}>📍 Route 53 DNS</div>
              <div>roboshops.* → CloudFront</div>
              <div>dev.* → Frontend ALB</div>
              <div>*.backend-dev.* → Backend ALB</div>
              <div>mongodb/redis/mysql/rabbitmq-dev.* → EC2 private IP</div>
            </div>
            <div style={{ flex: 1, border: "1px solid rgba(255,255,255,0.08)", borderRadius: 8, padding: "10px 14px", fontSize: 10, color: "#64748b" }}>
              <div style={{ color: "#94a3b8", fontWeight: 700, marginBottom: 5 }}>🔐 AWS SSM Parameters</div>
              <div>/roboshop/dev/mysql/mysql_root_password</div>
              <div style={{ marginTop: 5, color: "#94a3b8", fontWeight: 700, marginBottom: 5 }}>🏷️ Golden AMI Flow</div>
              <div>Terraform → EC2 → Ansible role</div>
              <div>→ Stop → AMI snapshot → Terminate</div>
              <div>→ Launch Template → ASG (min:1 max:10)</div>
            </div>
          </div>
        </div>

        <div style={{ width: 260, flexShrink: 0 }}>
          <div style={{ border: "1px solid rgba(255,255,255,0.1)", borderRadius: 10, padding: 16, position: "sticky", top: 20, background: "rgba(255,255,255,0.03)", minHeight: 200 }}>
            {!selected ? (
              <div style={{ color: "#475569", fontSize: 11, textAlign: "center", paddingTop: 40 }}>
                <div style={{ fontSize: 28, marginBottom: 10 }}>👆</div>
                Click any component<br/>to see details
              </div>
            ) : (
              <>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                  <div>
                    <div style={{ fontSize: 20 }}>{selService.icon}</div>
                    <div style={{ fontSize: 14, fontWeight: 800, color: "#f1f5f9", marginTop: 4 }}>{selService.label}</div>
                  </div>
                  <button onClick={() => setSelected(null)} style={{ background: "none", border: "none", color: "#64748b", cursor: "pointer", fontSize: 16 }}>✕</button>
                </div>
                {selService.runtime && (
                  <div style={{ fontSize: 10, display: "inline-block", padding: "2px 7px", borderRadius: 4, background: runtimeColor[selService.runtime] + "25", color: runtimeColor[selService.runtime], fontWeight: 700, marginBottom: 10, letterSpacing: 0.5 }}>{selService.runtime.toUpperCase()}</div>
                )}
                <div style={{ fontSize: 11, color: "#94a3b8", lineHeight: 1.5, marginBottom: 14 }}>{sel.desc}</div>
                {sel.notes.length > 0 && (
                  <>
                    <div style={{ fontSize: 10, fontWeight: 700, color: "#64748b", letterSpacing: 1, textTransform: "uppercase", marginBottom: 8 }}>Details</div>
                    {sel.notes.map((n, i) => (
                      <div key={i} style={{ display: "flex", gap: 6, marginBottom: 6, fontSize: 10.5, color: "#94a3b8", lineHeight: 1.4 }}>
                        <span style={{ color: "#475569", flexShrink: 0 }}>▸</span><span>{n}</span>
                      </div>
                    ))}
                  </>
                )}
                {connections[selected] && (
                  <>
                    <div style={{ fontSize: 10, fontWeight: 700, color: "#64748b", letterSpacing: 1, textTransform: "uppercase", marginTop: 14, marginBottom: 8 }}>Connects To</div>
                    <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                      {connections[selected].map(id => (
                        <button key={id} onClick={() => setSelected(id)} style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 5, padding: "3px 8px", fontSize: 10, color: "#94a3b8", cursor: "pointer", fontFamily: "inherit" }}>
                          {services[id].icon} {services[id].label}
                        </button>
                      ))}
                    </div>
                  </>
                )}
              </>
            )}
          </div>
          <div style={{ marginTop: 14, border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, padding: 14 }}>
            <div style={{ fontSize: 10, fontWeight: 700, color: "#64748b", letterSpacing: 1, textTransform: "uppercase", marginBottom: 10 }}>Runtime Legend</div>
            {Object.entries(runtimeColor).map(([rt, color]) => (
              <div key={rt} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                <div style={{ width: 3, height: 14, background: color, borderRadius: 2 }} />
                <div style={{ fontSize: 10.5, color: "#94a3b8", textTransform: "uppercase", fontWeight: 600 }}>{rt}</div>
              </div>
            ))}
            <div style={{ marginTop: 12, fontSize: 10, fontWeight: 700, color: "#64748b", letterSpacing: 1, textTransform: "uppercase", marginBottom: 8 }}>Subnet Zones</div>
            {[["#f6ad55","Edge (CloudFront)"],["#68d391","Public (ALBs, VPN, Bastion)"],["#63b3ed","Private (ASGs)"],["#f687b3","Database (EC2 DBs)"]].map(([c,l]) => (
              <div key={l} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 5 }}>
                <div style={{ width: 10, height: 10, borderRadius: 2, border: `1.5px dashed ${c}60`, flexShrink: 0 }} />
                <div style={{ fontSize: 10, color: "#94a3b8" }}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
</script>
</body>
</html>

![Architecture Diagram](roboshop-infra-dev.drawio.svg)

---

## Architecture Overview

Traffic flows through the following layers:

```
Internet
   │
   ▼
CloudFront (CDN)  ──  geo-restriction, caching, HTTPS-only
   │
   ▼
Frontend ALB (public, HTTPS/443)
   │
   ▼
Frontend EC2 (ASG, private subnet)
   │
   ▼
Backend ALB (internal, HTTP/80)  ──  host-header routing per microservice
   │
   ├── Catalogue  (port 8080, MongoDB)
   ├── User       (port 8080, MongoDB + Redis)
   ├── Cart       (port 8080, Redis + Catalogue)
   ├── Shipping   (port 8080, MySQL)
   └── Payment    (port 8080, RabbitMQ + User + Cart)
         │
         ▼
   Databases (isolated database subnet)
   ├── MongoDB    (port 27017)
   ├── Redis      (port 6379)
   ├── MySQL      (port 3306)
   └── RabbitMQ   (port 5672 / 15672)
```

All backend services and databases are in **private/database subnets**. Administrative access is via a **Bastion host** or **OpenVPN** in the public subnet.

---

## Repository Structure

Each numbered directory is an independent Terraform module/layer, applied in sequence:

| Directory | Purpose |
|---|---|
| `00-VPC` | VPC, public/private/database subnets, NAT gateway, VPC peering |
| `10-SG` | Security groups and ingress rules for every component |
| `20-bastion` | Bastion EC2 instance for emergency SSH access |
| `30-VPN` | OpenVPN EC2 instance for secure developer access |
| `40-databases` | MongoDB, Redis, MySQL, RabbitMQ on EC2 + Route53 DNS |
| `50-backend-alb` | Internal Application Load Balancer for microservices |
| `60-acm` | ACM wildcard SSL certificate with DNS validation |
| `60-catalogue` | Catalogue service — golden AMI + Launch Template + ASG |
| `70-frontend-alb` | Public-facing HTTPS ALB for the frontend |
| `80-components` | All 5 backend microservices + frontend via reusable module |
| `90-user` | Standalone user service (legacy/reference) |
| `91-cdn` | CloudFront distribution + Route53 alias |

---

## Infrastructure Design Patterns

### Golden AMI Pattern (for microservices)

Each microservice follows this immutable infrastructure pattern:

1. Launch a base EC2 instance
2. Run the bootstrap script to install and configure the application
3. Stop the instance
4. Snapshot it into an AMI
5. Terminate the source instance
6. Create a Launch Template from the AMI
7. Deploy an Auto Scaling Group using the Launch Template

This means deployments are fast, consistent, and rollback-friendly — a new AMI version triggers a rolling ASG refresh.

### Auto Scaling

All microservices use **Target Tracking Scaling** with a 75% average CPU utilization target. Rolling instance refresh is configured with a 50% minimum healthy percentage and is triggered automatically on Launch Template changes.

### Networking — Three-Tier Subnet Layout

| Tier | CIDR Range | Resources |
|---|---|---|
| Public | `10.0.1.0/24`, `10.0.2.0/24` | Frontend ALB, Bastion, VPN |
| Private | `10.0.11.0/24`, `10.0.12.0/24` | Microservice ASGs, Backend ALB |
| Database | `10.0.21.0/24`, `10.0.22.0/24` | MongoDB, Redis, MySQL, RabbitMQ |

VPC peering is enabled for cross-environment connectivity.

### Security Group Rules Summary

| Source → Target | Ports Allowed |
|---|---|
| Internet → Frontend ALB | 80, 443 |
| Internet → VPN | 22, 443, 943, 1194 |
| Internet → Bastion | 22 |
| Frontend ALB → Frontend | 80 |
| Frontend / Cart / Shipping / Payment → Backend ALB | 80 |
| Backend ALB → Microservices | 8080 |
| VPN / Bastion → Microservices | 22, 8080 |
| Catalogue / User → MongoDB | 27017 |
| User / Cart → Redis | 6379 |
| Shipping → MySQL | 3306 |
| Payment → RabbitMQ | 5672 |

### CDN Configuration

CloudFront sits in front of the Frontend ALB and is configured with:

- **Default cache behaviour**: caching disabled (suitable for dynamic app content)
- **`/media/*` path**: caching enabled
- **HTTPS-only** viewer protocol
- **Geo-restriction**: US, CA, GB, DE, FR, IN, AU
- **Price class**: PriceClass_200 (North America, Europe, Asia Pacific)
- **ACM certificate** for TLS termination at the edge

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- An existing Route53 hosted zone
- An IAM role named `EC2FORTERRAFORMADMIN` for the Bastion instance
- An IAM instance profile named `ec2fetchssmparameter` for MySQL (SSM access)

---

## Deployment Order

Layers must be applied **in numerical order** because each layer reads outputs from the previous ones via SSM Parameter Store.

```bash
# 1. VPC
cd 00-VPC && terraform init && terraform apply

# 2. Security Groups
cd ../10-SG && terraform init && terraform apply

# 3. Bastion & VPN (can be done in parallel)
cd ../20-bastion && terraform init && terraform apply
cd ../30-VPN     && terraform init && terraform apply

# 4. Databases
cd ../40-databases && terraform init && terraform apply

# 5. Backend ALB
cd ../50-backend-alb && terraform init && terraform apply

# 6. ACM Certificate
cd ../60-acm && terraform init && terraform apply

# 7. All microservices (golden AMI build — takes 10–15 min)
cd ../80-components && terraform init && terraform apply

# 8. Frontend ALB
cd ../70-frontend-alb && terraform init && terraform apply

# 9. CloudFront CDN
cd ../91-cdn && terraform init && terraform apply
```

> **Note:** The `80-components` step builds golden AMIs. Each microservice boots, gets bootstrapped, is snapshotted, and the source instance is terminated automatically. This is the longest step.

---

## Configuration

### Common Variables

Each layer accepts these shared variables:

| Variable | Default | Description |
|---|---|---|
| `project` | `roboshop` | Project name prefix for all resource names |
| `environment` | `dev` | Environment (dev / staging / prod) |
| `zone_name` | — | Route53 hosted zone domain name |
| `zone_id` | — | Route53 hosted zone ID |

These are typically set via `parameters.tf` (SSM) or a `terraform.tfvars` file.

### Microservice Components (80-components)

The `components` variable in `80-components/variables.tf` controls which services are deployed and their ALB listener rule priorities:

```hcl
variable "components" {
  default = {
    catalogue = { rule_priority = 10 }
    user      = { rule_priority = 20 }
    cart      = { rule_priority = 30 }
    shipping  = { rule_priority = 40 }
    payment   = { rule_priority = 50 }
    frontend  = { rule_priority = 10 }
  }
}
```

---

## Remote Modules Used

| Module | Source |
|---|---|
| VPC | `github.com/Sangala632/terraform-aws-vpc` |
| Security Groups | `github.com/daws-84s/terraform-aws-securitygroup` |
| Microservice (ASG + ALB) | `github.com/Sangala632/terraform-infra-aws` |
| ALB | `terraform-aws-modules/alb/aws` v9.16.0 |

---

## DNS Naming Convention

| Record | Resolves To |
|---|---|
| `roboshops.<zone_name>` | CloudFront distribution |
| `<env>.<zone_name>` | Frontend ALB |
| `*.backend-<env>.<zone_name>` | Backend ALB (wildcard) |
| `catalogue.backend-<env>.<zone_name>` | Catalogue service |
| `mongodb-<env>.<zone_name>` | MongoDB EC2 private IP |
| `redis-<env>.<zone_name>` | Redis EC2 private IP |
| `mysql-<env>.<zone_name>` | MySQL EC2 private IP |
| `rabbitmq-<env>.<zone_name>` | RabbitMQ EC2 private IP |

---

## Teardown

Destroy in **reverse order** to avoid dependency errors:

```bash
cd 91-cdn       && terraform destroy
cd 70-frontend-alb && terraform destroy
cd 80-components && terraform destroy
cd 60-acm       && terraform destroy
cd 50-backend-alb && terraform destroy
cd 40-databases  && terraform destroy
cd 30-VPN       && terraform destroy
cd 20-bastion   && terraform destroy
cd 10-SG        && terraform destroy
cd 00-VPC       && terraform destroy
```

> **CloudFront note:** CloudFront distributions must be disabled before they can be deleted. If `terraform destroy` fails on the CDN layer, disable the distribution in the AWS console first, wait for `Status: Deployed`, then re-run destroy.

---

## Cost Considerations

The following resources incur charges even when idle. Shut them down when not in use:

- **NAT Gateway** (~$30/month)
- **Application Load Balancers** (x2 — backend + frontend)
- **EC2 instances** (databases + bastion + VPN)
- **CloudFront** (charged on requests and data transfer)

EC2 instances for microservices are managed by ASGs and can be scaled to zero outside of business hours.
