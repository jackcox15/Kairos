#!/usr/bin/env python3

import pygame
import sys
import os
import glob
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core import RNodeBox

class Colors:
    BG_DARK = (20, 20, 25)
    BG_MEDIUM = (35, 35, 42)
    BG_LIGHT = (50, 50, 60)
    
    TEXT_PRIMARY = (240, 240, 245)
    TEXT_SECONDARY = (180, 180, 190)
    TEXT_DIM = (120, 120, 130)
    
    PURPLE_LIGHT = (180, 140, 255)
    PURPLE_MEDIUM = (140, 100, 220)
    PURPLE_DARK = (100, 70, 180)
    
    GREEN = (100, 220, 150)
    RED = (255, 120, 120)
    YELLOW = (255, 200, 100)
    ORANGE = (255, 160, 80)
    BLUE = (100, 180, 255)
    
    BORDER = (80, 80, 90)
    FOCUS = (255, 180, 0)

class Scale:
    def __init__(self, width, height):
        self.base_width = 800
        self.base_height = 480
        self.width_scale = width / self.base_width
        self.height_scale = height / self.base_height
        self.scale = min(self.width_scale, self.height_scale)
    
    def w(self, value):
        return int(value * self.width_scale)
    
    def h(self, value):
        return int(value * self.height_scale)
    
    def font(self, size):
        return int(size * self.scale)

class Tile:
    def __init__(self, x, y, width, height, title, screen_name):
        self.rect = pygame.Rect(x, y, width, height)
        self.title = title
        self.screen_name = screen_name
        self.hover = False
        self.focused = False
        self.status_color = Colors.TEXT_DIM
        self.status_text = ""
        self.detail_text = ""
    
    def draw(self, screen_surface, font_title, font_detail):
        if self.focused:
            bg_color = Colors.BG_LIGHT
            border_color = Colors.FOCUS
            border_width = 4
        elif self.hover:
            bg_color = Colors.BG_LIGHT
            border_color = Colors.PURPLE_LIGHT
            border_width = 2
        else:
            bg_color = Colors.BG_MEDIUM
            border_color = Colors.BORDER
            border_width = 2
        
        pygame.draw.rect(screen_surface, bg_color, self.rect, border_radius=12)
        pygame.draw.rect(screen_surface, border_color, self.rect, border_width, border_radius=12)
        
        title_surface = font_title.render(self.title, True, Colors.PURPLE_LIGHT)
        title_rect = title_surface.get_rect(left=self.rect.x + 15, top=self.rect.y + 15)
        screen_surface.blit(title_surface, title_rect)
        
        if self.status_text:
            status_surface = font_detail.render(self.status_text, True, self.status_color)
            status_rect = status_surface.get_rect(left=self.rect.x + 15, top=self.rect.y + 55)
            screen_surface.blit(status_surface, status_rect)
        
        if self.detail_text:
            detail_surface = font_detail.render(self.detail_text, True, Colors.TEXT_SECONDARY)
            detail_rect = detail_surface.get_rect(left=self.rect.x + 15, bottom=self.rect.bottom - 15)
            screen_surface.blit(detail_surface, detail_rect)
    
    def contains_point(self, x, y):
        return self.rect.collidepoint(x, y)

class Button:
    def __init__(self, x, y, width, height, text, color=None):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.color = color or Colors.PURPLE_MEDIUM
        self.hover = False
        self.focused = False
    
    def draw(self, screen, font):
        if self.focused:
            color = Colors.ORANGE
            border_width = 4
        elif self.hover:
            color = Colors.PURPLE_LIGHT
            border_width = 2
        else:
            color = self.color
            border_width = 2
        
        pygame.draw.rect(screen, color, self.rect, border_radius=8)
        pygame.draw.rect(screen, Colors.BORDER if not self.focused else Colors.FOCUS, 
                        self.rect, border_width, border_radius=8)
        
        text_surface = font.render(self.text, True, Colors.TEXT_PRIMARY)
        text_rect = text_surface.get_rect(center=self.rect.center)
        screen.blit(text_surface, text_rect)
    
    def contains_point(self, x, y):
        return self.rect.collidepoint(x, y)

class RNodeGUI:
    def __init__(self):
        self.box = RNodeBox()
        self.running = True
        self.current_screen = "dashboard"
        
        os.environ['SDL_AUDIODRIVER'] = 'dummy'
        pygame.init()
        
        try:
            info = pygame.display.Info()
            self.width = info.current_w if info.current_w > 0 else 800
            self.height = info.current_h if info.current_h > 0 else 480
        except:
            self.width = 800
            self.height = 480
        
        try:
            self.screen = pygame.display.set_mode((self.width, self.height), pygame.FULLSCREEN)
        except:
            self.screen = pygame.display.set_mode((self.width, self.height))
        
        pygame.display.set_caption("RNode Box")
        pygame.mouse.set_visible(True)
        
        self.scale = Scale(self.width, self.height)
        
        self.font_title = pygame.font.Font(None, self.scale.font(53))
        self.font_header = pygame.font.Font(None, self.scale.font(37))
        self.font_large = pygame.font.Font(None, self.scale.font(33))
        self.font_medium = pygame.font.Font(None, self.scale.font(27))
        self.font_small = pygame.font.Font(None, self.scale.font(23))
        
        self.logo = None
        self.logo_rect = None
        logo_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'assets', 'rns_logo.png')
        try:
            logo_img = pygame.image.load(logo_path)
            logo_size = self.scale.h(89)
            self.logo = pygame.transform.scale(logo_img, (logo_size, logo_size))
        except:
            pass
        
        self.data = {}
        self.last_refresh = 0
        self.refresh_interval = 2000
        
        self.tiles = []
        self.buttons = []
        self.focusables = []
        self.focused_index = -1
        
        self.refresh_data()
    
    def refresh_data(self):
        try:
            self.data['services'] = self.box.get_all_services()
            self.data['identity'] = self.box.get_reticulum_identity()
            self.data['nodes'] = self.box.get_mesh_node_count()
            self.data['paths'] = self.box.get_path_table()
            self.data['ap_info'] = self.box.get_ap_info()
            self.data['clients'] = self.box.get_ap_clients_count()
            self.data['cpu_temp'] = self.box.get_cpu_temp()
            self.data['cpu_usage'] = self.box.get_cpu_usage()
            self.data['memory'] = self.box.get_memory_usage()
            self.data['disk'] = self.box.get_disk_usage()
            self.data['uptime'] = self.box.get_uptime()
            self.data['interfaces'] = self.box.get_all_interface_stats()
            self.data['lora_devices'] = glob.glob('/dev/ttyUSB*') + glob.glob('/dev/ttyACM*')
            self.data['vpn_active'] = os.path.exists('/sys/class/net/wg0') or os.path.exists('/sys/class/net/tun0')
        except:
            pass
    
    def draw_text(self, text, x, y, font, color, align="left"):
        text_surface = font.render(str(text), True, color)
        if align == "center":
            rect = text_surface.get_rect(center=(x, y))
        elif align == "right":
            rect = text_surface.get_rect(right=x, top=y)
        else:
            rect = text_surface.get_rect(left=x, top=y)
        self.screen.blit(text_surface, rect)
    
    def draw_status_bar(self):
        bar_height = self.scale.h(90)
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, (0, 0, self.width, bar_height))
        pygame.draw.line(self.screen, Colors.BORDER, (0, bar_height), (self.width, bar_height), 2)
        
        self.draw_text("RNODE BOX", self.scale.w(15), self.scale.h(15), self.font_title, Colors.PURPLE_LIGHT)
        
        if self.logo:
            logo_x = self.width - self.logo.get_width() - self.scale.w(15)
            logo_y = self.scale.h(2)
            self.logo_rect = pygame.Rect(logo_x, logo_y, self.logo.get_width(), self.logo.get_height())
            self.screen.blit(self.logo, (logo_x, logo_y))
            
            mouse_pos = pygame.mouse.get_pos()
            if self.logo_rect.collidepoint(mouse_pos):
                pygame.draw.rect(self.screen, Colors.PURPLE_LIGHT, self.logo_rect, 2, border_radius=8)
        
        stats_y = self.scale.h(55)
        stat_spacing = self.scale.w(120)
        
        temp = self.data.get('cpu_temp', 0)
        temp_color = Colors.RED if temp > 70 else Colors.YELLOW if temp > 60 else Colors.GREEN
        self.draw_text(f"{temp:.0f}°C", self.scale.w(15), stats_y, self.font_medium, temp_color)
        
        mem = self.data.get('memory', {}).get('percent', 0)
        mem_color = Colors.RED if mem > 80 else Colors.YELLOW if mem > 60 else Colors.GREEN
        self.draw_text(f"{mem}%", self.scale.w(15) + stat_spacing, stats_y, self.font_medium, mem_color)
        
        disk = int(self.data.get('disk', {}).get('percent', 0))
        disk_color = Colors.RED if disk > 80 else Colors.YELLOW if disk > 60 else Colors.GREEN
        self.draw_text(f"{disk}%", self.scale.w(15) + stat_spacing * 2, stats_y, self.font_medium, disk_color)
        
        uptime = self.data.get('uptime', '')
        self.draw_text(uptime, self.scale.w(15) + stat_spacing * 3, stats_y, self.font_medium, Colors.TEXT_DIM)
    
    def draw_dashboard(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        bottom_margin = self.scale.h(20)
        available_height = self.height - y_start - bottom_margin
        
        gap = self.scale.w(15)
        tile_width = (self.width - gap * 3) // 2
        tile_height = (available_height - gap) // 2
        
        self.tiles = []
        self.focusables = []
        
        services = self.data.get('services', {})
        running = sum(1 for s in services.values() if s)
        total = len(services)
        
        tile1 = Tile(gap, y_start, tile_width, tile_height, "SERVICES", "services")
        tile1.status_text = f"{running}/{total} Running"
        tile1.status_color = Colors.GREEN if running == total else Colors.YELLOW if running > 0 else Colors.RED
        tile1.detail_text = "Tap for details"
        
        tile2 = Tile(gap * 2 + tile_width, y_start, tile_width, tile_height, "MESH", "mesh")
        tile2.status_text = f"{self.data.get('nodes', 0)} Nodes"
        tile2.status_color = Colors.GREEN if self.data.get('nodes', 0) > 0 else Colors.YELLOW
        identity = self.data.get('identity', 'Unknown')
        tile2.detail_text = identity[:16] + "..." if len(identity) > 16 else identity
        
        interfaces = self.data.get('interfaces', {})
        lora_count = len(self.data.get('lora_devices', []))
        tile3 = Tile(gap, y_start + tile_height + gap, tile_width, tile_height, "INTERFACES", "interfaces")
        tile3.status_text = f"{len(interfaces)} Network"
        tile3.status_color = Colors.GREEN
        tile3.detail_text = f"{lora_count} LoRa detected" if lora_count > 0 else "Tap for stats"
        
        ap_info = self.data.get('ap_info', {})
        clients = self.data.get('clients', 0)
        tile4 = Tile(gap * 2 + tile_width, y_start + tile_height + gap, tile_width, tile_height, "ACCESS POINT", "access_point")
        if ap_info.get('ssid', 'Not configured') != 'Not configured':
            tile4.status_text = f"{clients} Clients"
            tile4.status_color = Colors.GREEN if clients > 0 else Colors.YELLOW
            tile4.detail_text = f"{ap_info.get('ssid', 'N/A')}"
        else:
            tile4.status_text = "Not Configured"
            tile4.status_color = Colors.RED
            tile4.detail_text = "Tap to view"
        
        self.tiles = [tile1, tile2, tile3, tile4]
        self.focusables = [tile1, tile2, tile3, tile4]
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
        
        for tile in self.tiles:
            tile.draw(self.screen, self.font_header, self.font_large)
    
    def draw_services_screen(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        
        self.draw_text("SERVICE MANAGEMENT", self.scale.w(15), y_start, self.font_header, Colors.PURPLE_LIGHT)
        
        y_pos = y_start + self.scale.h(50)
        
        services = self.data.get('services', {})
        self.buttons = []
        self.focusables = []
        
        for service, status in services.items():
            card_width = self.width - self.scale.w(30)
            card_height = self.scale.h(75)
            
            pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                           (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
            pygame.draw.rect(self.screen, Colors.BORDER, 
                           (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
            
            status_color = Colors.GREEN if status else Colors.RED
            status_text = "RUNNING" if status else "STOPPED"
            
            self.draw_text(service.upper(), self.scale.w(25), y_pos + self.scale.h(15), 
                         self.font_large, Colors.TEXT_PRIMARY)
            self.draw_text(status_text, self.scale.w(25), y_pos + self.scale.h(45), 
                         self.font_medium, status_color)
            
            btn_width = self.scale.w(95)
            btn_height = self.scale.h(38)
            btn_x = self.width - self.scale.w(215)
            btn_y = y_pos + self.scale.h(18)
            
            restart_btn = Button(btn_x, btn_y, btn_width, btn_height, "Restart", Colors.YELLOW)
            restart_btn.service = service
            restart_btn.action = "restart"
            restart_btn.draw(self.screen, self.font_medium)
            self.buttons.append(restart_btn)
            self.focusables.append(restart_btn)
            
            stop_btn = Button(btn_x + btn_width + self.scale.w(8), btn_y, btn_width, btn_height, 
                            "Stop" if status else "Start", Colors.RED if status else Colors.GREEN)
            stop_btn.service = service
            stop_btn.action = "stop" if status else "start"
            stop_btn.draw(self.screen, self.font_medium)
            self.buttons.append(stop_btn)
            self.focusables.append(stop_btn)
            
            y_pos += card_height + self.scale.h(12)
        
        if self.data.get('vpn_active'):
            self.draw_text("VPN: Active", self.scale.w(25), y_pos, self.font_medium, Colors.GREEN)
        
        back_btn = Button(self.scale.w(15), self.height - self.scale.h(65), 
                         self.scale.w(110), self.scale.h(50), "Back")
        back_btn.action = "back"
        back_btn.draw(self.screen, self.font_large)
        self.buttons.append(back_btn)
        self.focusables.append(back_btn)
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
    
    def draw_mesh_screen(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        
        self.draw_text("MESH NETWORK", self.scale.w(15), y_start, self.font_header, Colors.PURPLE_LIGHT)
        
        y_pos = y_start + self.scale.h(50)
        
        gap = self.scale.w(12)
        card_width = (self.width - gap * 3) // 2
        card_height = self.scale.h(80)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (gap, y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (gap, y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("Identity", gap + 12, y_pos + 12, self.font_medium, Colors.TEXT_SECONDARY)
        identity = self.data.get('identity', 'Unknown')
        max_chars = (card_width - 24) // 12
        id_display = identity[:max_chars] if len(identity) > max_chars else identity
        self.draw_text(id_display, gap + 12, y_pos + 45, self.font_medium, Colors.PURPLE_LIGHT)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (gap * 2 + card_width, y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (gap * 2 + card_width, y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("Nodes", gap * 2 + card_width + 12, y_pos + 12, self.font_medium, Colors.TEXT_SECONDARY)
        nodes = self.data.get('nodes', 0)
        node_color = Colors.GREEN if nodes > 0 else Colors.YELLOW
        self.draw_text(str(nodes), gap * 2 + card_width + 12, y_pos + 45, self.font_large, node_color)
        
        y_pos += card_height + gap
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (gap, y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (gap, y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("Paths", gap + 12, y_pos + 12, self.font_medium, Colors.TEXT_SECONDARY)
        paths = len(self.data.get('paths', []))
        self.draw_text(str(paths), gap + 12, y_pos + 45, self.font_large, Colors.TEXT_PRIMARY)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (gap * 2 + card_width, y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (gap * 2 + card_width, y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("Status", gap * 2 + card_width + 12, y_pos + 12, self.font_medium, Colors.TEXT_SECONDARY)
        status = "Connected" if nodes > 0 else "Isolated"
        status_color = Colors.GREEN if nodes > 0 else Colors.YELLOW
        self.draw_text(status, gap * 2 + card_width + 12, y_pos + 45, self.font_large, status_color)
        
        self.buttons = []
        self.focusables = []
        back_btn = Button(self.scale.w(15), self.height - self.scale.h(65), 
                         self.scale.w(110), self.scale.h(50), "Back")
        back_btn.action = "back"
        back_btn.draw(self.screen, self.font_large)
        self.buttons.append(back_btn)
        self.focusables.append(back_btn)
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
    
    def draw_interfaces_screen(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        
        self.draw_text("NETWORK INTERFACES", self.scale.w(15), y_start, self.font_header, Colors.PURPLE_LIGHT)
        
        y_pos = y_start + self.scale.h(50)
        
        interfaces = self.data.get('interfaces', {})
        
        for iface, stats in interfaces.items():
            card_height = self.scale.h(85)
            card_width = self.width - self.scale.w(30)
            
            pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                           (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
            pygame.draw.rect(self.screen, Colors.BORDER, 
                           (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
            
            self.draw_text(iface.upper(), self.scale.w(25), y_pos + self.scale.h(15), 
                         self.font_large, Colors.TEXT_PRIMARY)
            
            rx = self.box.format_bytes(stats.get('rx_bytes', 0))
            tx = self.box.format_bytes(stats.get('tx_bytes', 0))
            
            self.draw_text(f"↓ {rx}", self.scale.w(25), y_pos + self.scale.h(50), 
                         self.font_medium, Colors.GREEN)
            self.draw_text(f"↑ {tx}", self.scale.w(200), y_pos + self.scale.h(50), 
                         self.font_medium, Colors.PURPLE_LIGHT)
            
            y_pos += card_height + self.scale.h(12)
        
        lora_devices = self.data.get('lora_devices', [])
        if lora_devices:
            for dev in lora_devices:
                card_height = self.scale.h(60)
                card_width = self.width - self.scale.w(30)
                
                pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                               (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
                pygame.draw.rect(self.screen, Colors.BORDER, 
                               (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
                
                self.draw_text(f"LoRa: {dev}", self.scale.w(25), y_pos + self.scale.h(20), 
                             self.font_medium, Colors.BLUE)
                
                y_pos += card_height + self.scale.h(8)
        
        self.buttons = []
        self.focusables = []
        back_btn = Button(self.scale.w(15), self.height - self.scale.h(65), 
                         self.scale.w(110), self.scale.h(50), "Back")
        back_btn.action = "back"
        back_btn.draw(self.screen, self.font_large)
        self.buttons.append(back_btn)
        self.focusables.append(back_btn)
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
    
    def draw_access_point_screen(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        
        self.draw_text("ACCESS POINT", self.scale.w(15), y_start, self.font_header, Colors.PURPLE_LIGHT)
        
        y_pos = y_start + self.scale.h(50)
        
        ap_info = self.data.get('ap_info', {})
        clients = self.data.get('clients', 0)
        
        card_height = self.scale.h(75)
        card_width = self.width - self.scale.w(30)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("SSID", self.scale.w(25), y_pos + self.scale.h(15), 
                     self.font_medium, Colors.TEXT_SECONDARY)
        
        ssid = ap_info.get('ssid', 'Not configured')
        ssid_color = Colors.GREEN if ssid != 'Not configured' else Colors.RED
        self.draw_text(ssid, self.scale.w(25), y_pos + self.scale.h(45), 
                     self.font_large, ssid_color)
        
        y_pos += card_height + self.scale.h(12)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("IP Address", self.scale.w(25), y_pos + self.scale.h(15), 
                     self.font_medium, Colors.TEXT_SECONDARY)
        self.draw_text(ap_info.get('ip', 'N/A'), self.scale.w(25), y_pos + self.scale.h(45), 
                     self.font_large, Colors.TEXT_PRIMARY)
        
        y_pos += card_height + self.scale.h(12)
        
        pygame.draw.rect(self.screen, Colors.BG_MEDIUM, 
                       (self.scale.w(15), y_pos, card_width, card_height), border_radius=8)
        pygame.draw.rect(self.screen, Colors.BORDER, 
                       (self.scale.w(15), y_pos, card_width, card_height), 2, border_radius=8)
        
        self.draw_text("Clients", self.scale.w(25), y_pos + self.scale.h(15), 
                     self.font_medium, Colors.TEXT_SECONDARY)
        
        client_color = Colors.GREEN if clients > 0 else Colors.TEXT_DIM
        self.draw_text(f"{clients} Connected", self.scale.w(25), y_pos + self.scale.h(45), 
                     self.font_large, client_color)
        
        self.buttons = []
        self.focusables = []
        back_btn = Button(self.scale.w(15), self.height - self.scale.h(65), 
                         self.scale.w(110), self.scale.h(50), "Back")
        back_btn.action = "back"
        back_btn.draw(self.screen, self.font_large)
        self.buttons.append(back_btn)
        self.focusables.append(back_btn)
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
    
    def draw_settings_screen(self):
        bar_height = self.scale.h(90)
        y_start = bar_height + self.scale.h(15)
        
        self.draw_text("SYSTEM SETTINGS", self.scale.w(15), y_start, self.font_header, Colors.PURPLE_LIGHT)
        
        self.draw_text("Configuration options coming soon", 
                     self.width // 2, self.height // 2, 
                     self.font_medium, Colors.TEXT_DIM, align="center")
        
        self.buttons = []
        self.focusables = []
        back_btn = Button(self.scale.w(15), self.height - self.scale.h(65), 
                         self.scale.w(110), self.scale.h(50), "Back")
        back_btn.action = "back"
        back_btn.draw(self.screen, self.font_large)
        self.buttons.append(back_btn)
        self.focusables.append(back_btn)
        
        for i, item in enumerate(self.focusables):
            item.focused = (i == self.focused_index)
    
    def handle_keyboard_navigation(self, event):
        if event.key == pygame.K_TAB:
            if len(self.focusables) > 0:
                self.focused_index = (self.focused_index + 1) % len(self.focusables)
        
        elif event.key == pygame.K_RETURN or event.key == pygame.K_SPACE:
            if 0 <= self.focused_index < len(self.focusables):
                item = self.focusables[self.focused_index]
                
                if hasattr(item, 'screen_name'):
                    self.current_screen = item.screen_name
                    self.focused_index = -1
                
                elif hasattr(item, 'action'):
                    if item.action == "back":
                        self.current_screen = "dashboard"
                        self.focused_index = -1
                    elif item.action == "restart":
                        self.box.restart_service(item.service)
                        self.refresh_data()
                    elif item.action == "stop":
                        os.system(f"sudo systemctl stop {item.service}")
                        self.refresh_data()
                    elif item.action == "start":
                        os.system(f"sudo systemctl start {item.service}")
                        self.refresh_data()
    
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                    if self.current_screen == "dashboard":
                        self.running = False
                    else:
                        self.current_screen = "dashboard"
                        self.focused_index = -1
                else:
                    self.handle_keyboard_navigation(event)
            
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                click_x, click_y = event.pos
                
                if self.logo_rect and self.logo_rect.collidepoint(click_x, click_y):
                    self.current_screen = "settings"
                    self.focused_index = -1
                
                elif self.current_screen == "dashboard":
                    for tile in self.tiles:
                        if tile.contains_point(click_x, click_y):
                            self.current_screen = tile.screen_name
                            self.focused_index = -1
                            break
                
                else:
                    for btn in self.buttons:
                        if btn.contains_point(click_x, click_y):
                            if btn.action == "back":
                                self.current_screen = "dashboard"
                                self.focused_index = -1
                            elif btn.action == "restart":
                                self.box.restart_service(btn.service)
                                self.refresh_data()
                            elif btn.action == "stop":
                                os.system(f"sudo systemctl stop {btn.service}")
                                self.refresh_data()
                            elif btn.action == "start":
                                os.system(f"sudo systemctl start {btn.service}")
                                self.refresh_data()
                            break
    
    def run(self):
        clock = pygame.time.Clock()
        
        while self.running:
            current_time = pygame.time.get_ticks()
            if current_time - self.last_refresh > self.refresh_interval:
                self.refresh_data()
                self.last_refresh = current_time
            
            self.screen.fill(Colors.BG_DARK)
            self.draw_status_bar()
            
            if self.current_screen == "dashboard":
                self.draw_dashboard()
            elif self.current_screen == "services":
                self.draw_services_screen()
            elif self.current_screen == "mesh":
                self.draw_mesh_screen()
            elif self.current_screen == "interfaces":
                self.draw_interfaces_screen()
            elif self.current_screen == "access_point":
                self.draw_access_point_screen()
            elif self.current_screen == "settings":
                self.draw_settings_screen()
            
            self.handle_events()
            
            pygame.display.flip()
            clock.tick(60)
        
        pygame.quit()


if __name__ == "__main__":
    if os.geteuid() != 0:
        print(" Limited functionality without root")
        print(" Run: sudo python3 gui.py")
    
    try:
        gui = RNodeGUI()
        gui.run()
    except KeyboardInterrupt:
        print("\nShutdown")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
