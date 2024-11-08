# Lab MPLS Project

Welcome to the Lab MPLS Project! This project is designed to help you understand and experiment with Multi-Protocol Label Switching (MPLS) in a controlled lab environment.

## Lab Diagram

![](mpls.clab.svg)

## Installation

To get started with the Lab MPLS Project, follow these steps:

1. Clone the repository:

    ```bash
    git clone https://github.com/aweher/lab-mpls.git
    ```

2. Navigate to the project directory:

    ```bash
    cd lab-mpls
    ```

3. Install ContainerLab (if not already installed)

    ```bash
    curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
    ```

4. Build Docker Containers

    ```bash
    cd frr-debian
    ./build.sh
    cd ..

    cd frr-ubuntu
    ./build.sh
    cd ..
    ```

5. Have fun!

    ```bash
    ./lab.sh run
    ```

## Contributing

We welcome contributions to the Lab MPLS Project! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

Developed by @ArielWeher
