resource "azurerm_public_ip" "lb" {
  name                = "pip-urlshortener-bg"
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "urlshortener-bg-demo"

  tags = {
    project = "url-shortener-blue-green"
  }
}

resource "azurerm_lb" "bg" {
  name                = "lb-urlshortener-bg"
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "blue" {
  name            = "pool-blue"
  loadbalancer_id = azurerm_lb.bg.id
}

resource "azurerm_lb_backend_address_pool" "green" {
  name            = "pool-green"
  loadbalancer_id = azurerm_lb.bg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "blue" {
  network_interface_id    = azurerm_network_interface.blue.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.blue.id
}

resource "azurerm_network_interface_backend_address_pool_association" "green" {
  network_interface_id    = azurerm_network_interface.green.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.green.id
}

resource "azurerm_lb_probe" "http" {
  name                = "urlshortener-health-probe"
  loadbalancer_id     = azurerm_lb.bg.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "active" {
  name                           = "active-http-rule"
  loadbalancer_id                = azurerm_lb.bg.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public"

  backend_address_pool_ids = (
    var.active_color == "blue"
    ? [azurerm_lb_backend_address_pool.blue.id]
    : [azurerm_lb_backend_address_pool.green.id]
  )

  probe_id             = azurerm_lb_probe.http.id
  disable_outbound_snat = true
}