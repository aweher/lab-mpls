#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import curses
import subprocess
import json

def get_running_nodes():
    result = subprocess.run(['sudo', 'containerlab', 'inspect', '--format', 'json'], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        return []
    try:
        data = json.loads(result.stdout)
        nodes = data.get('containers', [])
        running_nodes = [node['name'] for node in nodes if node['state'] == 'running']
        return running_nodes
    except json.JSONDecodeError:
        print("Failed to decode JSON")
        return []

def exec_docker_compose(container_name):
    curses.endwin()
    print(f"Executing sudo docker exec -ti {container_name} bash")
    subprocess.run(['sudo', 'docker', 'exec', '-ti', container_name, 'bash'])

def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)
    stdscr.clear()
    stdscr.refresh()

    while True:
        nodes = get_running_nodes()
        if not nodes:
            stdscr.addstr(0, 0, "No running nodes found.")
            stdscr.refresh()
            stdscr.getch()
            return

        current_row = 0

        while True:
            stdscr.clear()
            stdscr.addstr(0, 0, "Laboratorio Ayuda.LA", curses.A_BOLD)
            for idx, node in enumerate(nodes):
                x = 0
                y = idx + 1
                if idx == current_row:
                    stdscr.attron(curses.color_pair(1))
                    stdscr.addstr(y, x, node)
                    stdscr.attroff(curses.color_pair(1))
                else:
                    stdscr.addstr(y, x, node)
            stdscr.refresh()

            key = stdscr.getch()

            if key == curses.KEY_UP and current_row > 0:
                current_row -= 1
            elif key == curses.KEY_DOWN and current_row < len(nodes) - 1:
                current_row += 1
            elif key == ord('\n'):
                exec_docker_compose(nodes[current_row])
                break
            elif key == ord('q'):
                return

if __name__ == "__main__":
    curses.wrapper(main)