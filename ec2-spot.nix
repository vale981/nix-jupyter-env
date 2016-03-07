{
  ...
}:

let region = "us-east-1";
in
  {
    resources =
      {
        ec2KeyPairs.ec2-spot-jupyter = { inherit region; };
      };
    jupyter-ec2-spot =
      { resources, config, pkgs, nodes, lib, ... }:
      {
        imports =
          [
            # TODO
          ];

        services.journald = {
          rateLimitBurst = 0;
          rateLimitInterval = "0";
        };

        networking.firewall =
          {
            enable = true;
            allowedTCPPorts = [ 22 80 443 ];
          };

        deployment =
          {
            targetEnv = "ec2";
            ec2 =
              {
                region = "us-east-1";
                instanceType = "m4.xlarge";
                spotInstancePrice = 5;
                securityGroupIds =
                  [
                    "sg-xxxxxxxx" # "allow-ssh-by-ip"
                    "sg-xxxxxxxx" # "allow-http-by-ip"
                    "sg-xxxxxxxx" # "allow-outbound"
                  ];
                subnetId = "subnet-xxxxxxxx";
                keyPair = resources.ec2KeyPairs.ec2-spot-jupyter;
                elasticIPv4 = "xx.xx.xx.xxx";
                associatePublicIpAddress = true;
              };
          };
      };
  }
