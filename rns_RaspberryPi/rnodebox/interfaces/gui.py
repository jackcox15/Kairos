#!/usr/bin/env python3

import pygame
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core import RNodeBox

class RNodeGUI:
    
    def __init__(self):
        self.box = RNodeBox()
        self.running = True
        
        # disable audio to avoid ALSA errors
        os.environ['SDL_AUDIODRIVER'] = 'dummy'
        
        # init pygame - let SDL auto-detect video driver
        pygame.init()
        
        # get display size
        try:
            info = pygame.display.Info()
            self.width = info.current_w if info.current_w > 0 else 480
            self.height = info.current_h if info.current_h > 0 else 320
        except:
            self.width = 480
            self.height = 320
        
        # create fullscreen display
        try:
            self.screen = pygame.display.set_mode((self.width, self.height), pygame.FULLSCREEN)
        except:
            # fallback to windowed
            self.screen = pygame.display.set_mode((self.width, self.height))
        
        pygame.display.set_caption("RNode Box")
        pygame.mouse.set_visible(True)
        
        # colors
        self.BLACK = (0, 0, 0)
        self.WHITE = (255, 255, 255)
        self.GREEN = (0, 255, 0)
        self.RED = (255, 0, 0)
        self.BLUE = (0, 100, 255)
        self.GRAY = (128, 128, 128)
        
        # fonts
        self.font_large = pygame.font.Font(None, 36)
        self.font_medium = pygame.font.Font(None, 28)
        self.font_small = pygame.font.Font(None, 20)
        
        # refresh timer
        self.last_refresh = 0
        self.refresh_interval = 2000
        
        # data cache
        self.data = {}
        self.refresh_data()
    
    def refresh_data(self):
        self.data['services'] = self.box.get_all_services()
        self.data['identity'] = self.box.get_reticulum_identity()
        self.data['nodes'] = self.box.get_mesh_node_count()
        self.data['ap_info'] = self.box.get_ap_info()
        self.data['clients'] = self.box.get_ap_clients_count()
        self.data['cpu_temp'] = self.box.get_cpu_temp()
        self.data['memory'] = self.box.get_memory_usage()
        self.data['uptime'] = self.box.get_uptime()
    
    def draw_text(self, text, x, y, font, color):
        surface = font.render(text, True, color)
        self.screen.blit(surface, (x, y))
    
    def draw(self):
        self.screen.fill(self.BLACK)
        
        y = 10
        
        # title
        self.draw_text("RNODE BOX", 10, y, self.font_large, self.BLUE)
        y += 45
        
        # status bar
        temp_text = f"CPU: {self.data['cpu_temp']:.1f}C"
        mem_text = f"RAM: {self.data['memory']['percent']}%"
        uptime_text = f"Up: {self.data['uptime']}"
        
        self.draw_text(temp_text, 10, y, self.font_small, self.GRAY)
        self.draw_text(mem_text, 150, y, self.font_small, self.GRAY)
        self.draw_text(uptime_text, 280, y, self.font_small, self.GRAY)
        y += 30
        
        # separator
        pygame.draw.line(self.screen, self.GRAY, (10, y), (self.width - 10, y), 2)
        y += 15
        
        # services
        self.draw_text("SERVICES", 10, y, self.font_medium, self.WHITE)
        y += 30
        
        for service, status in self.data['services'].items():
            color = self.GREEN if status else self.RED
            symbol = "✓" if status else "✗"
            self.draw_text(f"{symbol} {service}", 20, y, self.font_small, color)
            y += 25
        
        y += 10
        
        # mesh info
        self.draw_text("MESH NETWORK", 10, y, self.font_medium, self.WHITE)
        y += 30
        
        identity_short = self.data['identity'][:16] + "..." if len(self.data['identity']) > 16 else self.data['identity']
        self.draw_text(f"ID: {identity_short}", 20, y, self.font_small, self.GRAY)
        y += 25
        self.draw_text(f"Nodes: {self.data['nodes']}", 20, y, self.font_small, self.GRAY)
        y += 30
        
        # access point
        self.draw_text("ACCESS POINT", 10, y, self.font_medium, self.WHITE)
        y += 30
        
        self.draw_text(f"SSID: {self.data['ap_info']['ssid']}", 20, y, self.font_small, self.GRAY)
        y += 25
        self.draw_text(f"IP: {self.data['ap_info']['ip']}", 20, y, self.font_small, self.GRAY)
        y += 25
        self.draw_text(f"Clients: {self.data['clients']}", 20, y, self.font_small, self.GRAY)
        
        # bottom instructions
        inst_y = self.height - 25
        self.draw_text("Press Q or ESC to exit", 10, inst_y, self.font_small, self.GRAY)
        
        pygame.display.flip()
    
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_q or event.key == pygame.K_ESCAPE:
                    self.running = False
    
    def run(self):
        clock = pygame.time.Clock()
        
        while self.running:
            current_time = pygame.time.get_ticks()
            if current_time - self.last_refresh > self.refresh_interval:
                self.refresh_data()
                self.last_refresh = current_time
            
            self.handle_events()
            self.draw()
            clock.tick(30)
        
        pygame.quit()


if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Warning: Some functions require root access")
        print("Run with: sudo python3 gui.py")
    
    gui = RNodeGUI()
    gui.run()
