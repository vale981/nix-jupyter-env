{
  ...
}:

{
  jupyter-vm = { resources, ... }:
    {
      deployment =
        {
          targetEnv = "virtualbox";
          virtualbox =
            {
              memorySize = 1024;
              headless = true;
            };
        };
    };
}
