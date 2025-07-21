<%#
  CinéRoom Admin Dashboard - Vue principale sans sidebar
  Structure: Header + Métriques + Graphiques + Tables de gestion
%>

<div
  class="admin-dashboard min-h-screen bg-dark-400"
  data-controller="admin-dashboard admin-chart admin-flash"
  data-admin-dashboard-refresh-interval-value="30000"
  data-admin-dashboard-auto-refresh-value="true"
>
  <!-- Header Hero Section -->
  <%= render 'admin/dashboard/header' %>

  <!-- Key Metrics Section -->
  <%= render 'admin/dashboard/metrics' %>

  <!-- Charts & Analytics Section -->
  <%= render 'admin/dashboard/charts' %>

  <!-- Management Tables Section -->
  <%= render 'admin/dashboard/management' %>

  <!-- Quick Actions Section -->
  <%= render 'admin/dashboard/quick_actions' %>

  <!-- System Status Section -->
  <%= render 'admin/dashboard/system_status' %>
</div>
