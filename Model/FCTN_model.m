classdef FCTN_model
    properties
        yTensor; E; num_observation; Sigma_E;
        rank; R_Factor; sz_Factor;
        lambda_a_0; lambda_b_0;
        tau_a_0; tau_b_0;
        epsilon_a_0; epsilon_b_0;
        dim; order; 
        Factors; T_Factor, lambda; tau; alphas; 
        prod_lambda;
        h;
        Fit; err_iter; hat; init_hat;initRMSE; RMSE_List;Xconv_List;
    end
    % consider Nth order tensor
    % Factors: (N,1)cell G_n
    % lamada: (N,N)cell lamada^{(k_1,k_2)}
    % prod_lamada: (N,1)cell 
    % h: (N,N)cell for (k_1,k_2) we have h_{k_1} and h_{k_2}, where h_{k_1} = h{k_1,k_2},h_{k_2} = h{k_2,k_1} 
    % R_Factor: R_Factor{n} = R(1,n)*...*R(n-1,n)*R(n,n+1)*...*R(n,N)
    methods
        % create object
        function obj = FCTN_model(yTensor, rank, hyperparameters)
            obj.yTensor = yTensor;
            obj.rank = rank;
            obj.tau_a_0 = hyperparameters.tau_a_0;
            obj.tau_b_0 = hyperparameters.tau_b_0;
            obj.lambda_a_0 = hyperparameters.lambda_a_0;
            obj.lambda_b_0 = hyperparameters.lambda_b_0;
            obj.epsilon_a_0 = hyperparameters.epsilon_a_0;
            obj.epsilon_b_0 = hyperparameters.epsilon_b_0;
        end

        % initialize parameter
        function self = initialize(self)
            self.dim = size(self.yTensor);  
            self.order = length(self.dim);
            N = self.order;
            self.num_observation = prod(self.dim);
            % request facotr matrix memory
            self.Factors = cell(N, 1);   % cell save Factor Matrix
            self.R_Factor = cell(N, 1);
            self.sz_Factor = cell(N, 1);
            self.lambda = cell(N, N);
            self.prod_lambda = cell(N, 1);
            self.T_Factor = cell(N,1);
            % self.Factors{n}: R(1,n)*...*R(n-1,n)*R(n,n+1)*...*R(n,N)*I_n
            for n = 1:N
                self.sz_Factor{n} = [];
                for i = 1:n-1
                    self.sz_Factor{n} = cat(2,self.sz_Factor{n},self.rank(i,n));
                end
                for i = n+1:N
                    self.sz_Factor{n} = cat(2,self.sz_Factor{n},self.rank(n,i));
                end
                % self.sz_Factor{n} now size: [R(1,n),...,R(n-1,n),R(n,n+1),...,R(n,N)]
                self.R_Factor{n} = prod(self.sz_Factor{n});
                % R_Factor{n} = R(1,n)*...*R(n-1,n)*R(n,n+1)*...*R(n,N)
                self.sz_Factor{n} = cat(2,self.sz_Factor{n},self.dim(n));
                % self.sz_Factor{n} now size: [R(1,n),...,R(n-1,n),R(n,n+1),...,R(n,N),I_n]
                self.Factors{n} = zeros(self.sz_Factor{n});
                % Initialise lambda
                for i = n+1:N
                    self.lambda{n,i} = ones(self.rank(n,i),1);
                end
            end

            for i = 1:N
                for j = 1:i-1
                    self.lambda{i,j} = self.lambda{j,i};
                    self.rank(i,j) = self.rank(j,i);
                end
            end

            % Facotrs Matrix 
            for n = 1:N
                self.T_Factor{n} = double(tenmat(self.Factors{n}, N));
            end 
            for n = 1:N
                self.prod_lambda{n} = khatrirao_fast(self.lambda{n,[1:n-1,n+1:N]},'r');
                for i = 1:self.dim(n)
                    self.T_Factor{n}(i,:) = mvnrnd(zeros(self.R_Factor{n}, 1), diag(self.prod_lambda{n}));
                end
                self.Factors{n} = reshape(self.T_Factor{n}',  self.sz_Factor{n});
            end


            % Initialise alpha, beta
            self.tau = (self.tau_a_0+eps)/(self.tau_b_0+eps);
            initVar = 1e-3;
            self.alphas = initVar.^(-1)*ones(self.dim).*((self.epsilon_a_0+eps)/(self.epsilon_b_0+eps));
            self.E = self.alphas.^(-0.5).*rand(self.dim);
            self.hat = double(tnprod_new(self.Factors));
            self.Sigma_E = self.alphas.^(-1).*ones(self.dim);
        end

        %% run model -burn-in
        function self = run(self, RUN_MAX_iterations)
            self.RMSE_List = [];
            self.Xconv_List = [];
            self.Fit = zeros(RUN_MAX_iterations,1);
            FitOld = 1e-8;
            self.init_hat = double(tnprod_new(self.Factors));
            self.initRMSE = sqrt( sum((self.yTensor(:)-self.init_hat(:)).^2)./length(self.yTensor(:)) );
            N = self.order;

            for iter=1:RUN_MAX_iterations

                old_Xhat = self.hat;
                old_E = self.E;
                for n = 1:N
                    self.T_Factor{n} = double(tenmat(self.Factors{n}, N));
                    self.prod_lambda{n} = khatrirao_fast(self.lambda{n,[1:n-1,n+1:N]},'r');
                    var1 = tnreshape_new(tnprod_rest_new(self.Factors,n),N);
                    var2 = var1 * var1';
                    var3 = self.tau * var2 + diag(self.prod_lambda{n});
                    v_Factor = var3^(-1);
                    FlashY = var1 * tenmat((self.yTensor - self.E), n)';
                    for i = 1:self.dim(n)
                        g_Factor = self.tau * v_Factor * FlashY(:,i);
                        g_Factor = g_Factor';
                        % T_1(i,:) = mvnrnd(g_Factor_1, v_Factor_1);
                        self.T_Factor{n}(i,:) = g_Factor;
                    end
                    self.Factors{n} = reshape(self.T_Factor{n}', self.sz_Factor{n});
                end
                
                % update lambda
                for k1 = 1:N-1
                    for k2 = k1+1:N
                        % update lambda^{(k1,k2)}
                        self.lambda{k1,k2} = self.upgrade_lambda_a(k1,k2) ./ self.upgrade_lambda_b(k1,k2);
                        self.lambda{k2,k1} = self.lambda{k1,k2};
                    end
                end
                
                self.hat = double(tnprod_new(self.Factors));
                self.tau = self.upgrade_tau_a() / self.upgrade_tau_b();
                self.Sigma_E = 1./(self.tau + self.alphas);
                self.E = double(self.tau*(self.yTensor-self.hat).*self.Sigma_E);
                self.alphas = self.upgrade_alpha_a() ./ self.upgrade_alpha_b();

                NormY = norm(self.yTensor(:));
                Y = self.yTensor;
                X = double(tnprod_new(self.Factors));
                EE2 = sum((self.E(:).^2 + self.Sigma_E(:)));
                err = Y(:)'*Y(:) - 2*Y(:)'*X(:) -2*Y(:)'*self.E(:) + 2*X(:)'*self.E(:) + X(:)'*X(:) + EE2;
                self.Fit(iter) = 1 - sqrt(err)/NormY;
                RelChan = abs(FitOld - self.Fit(iter));
                if self.Fit(iter) > 0
                    FitOld = self.Fit(iter);    
                else
                    FitOld = 1e-8;
                end

                Xconv = norm(old_Xhat(:) - self.hat(:))/norm(old_Xhat(:));
                self.Xconv_List = [self.Xconv_List,Xconv];
                Econv = norm(old_E(:) - self.E(:))/norm(old_E(:));
                tol = 1e-4; 
                if RelChan < tol && Xconv < tol && FitOld > 0.5
                    %fprintf('Iter %u: Fit = %f, FitTol = %f, Xconv = %g, Econv = %g, R = %s.\n', ...
                    %    iI, Fit(iI), RelChan, Xconv, Econv, mat2str(Rs));
                    disp('Evidence Lower Bound Converges.'); 
                    break; 
                end
                if mod(iter,10) == 0
                    fprintf('Iter %u: Fit = %f, FitTol = %f, Xconv = %g, Econv = %g\n', ...
                        iter, self.Fit(iter), RelChan, Xconv, Econv);
                end

                RMSE = sqrt( sum((self.yTensor(:)-self.hat(:)).^2)./length(self.yTensor(:)));
                self.RMSE_List = [self.RMSE_List, RMSE];
                
            end
            
        end
        
        %% update posterior parameter
        % lambda_a^{(k1,k2)}
        function lambda_a = upgrade_lambda_a(self,k1,k2)
            tmp1 = self.dim(k1) * prod(self.rank(k1,[1:k1-1,k1+1:k2-1,k2+1:self.order]));
            
            tmp2 = self.dim(k2) * prod(self.rank(k2,[1:k1-1,k1+1:k2-1,k2+1:self.order]));
            
            lambda_a = self.lambda_a_0 + 0.5*(tmp1 + tmp2) ;
            lambda_a = lambda_a .* ones(self.rank(k1,k2), 1);
        end

        % lambda_b^{(k1,k2)}
        function lambda_b = upgrade_lambda_b(self,k1,k2)
         
            self.h{k1,k2} = kr(khatrirao_fast(self.lambda{k1,[1:k1-1,k1+1:k2-1,k2+1:self.order]},'r'), ones(self.dim(k1),1));

            self.h{k2,k1} = kr(khatrirao_fast(self.lambda{k2,[1:k1-1,k1+1:k2-1,k2+1:self.order]},'r'), ones(self.dim(k2),1));

            tmp1 = double(tenmat(self.Factors{k1}, k2-1)) .* double(tenmat(self.Factors{k1}, k2-1));
            tmp2 = double(tenmat(self.Factors{k2}, k1)) .* double(tenmat(self.Factors{k2}, k1));
            tmp3 = self.h{k1,k2}' * tmp1';
            tmp4 = self.h{k2,k1}' * tmp2';
            tmp = tmp3' + tmp4';
            lambda_b = self.lambda_b_0 + 0.5*tmp;
        end
        
        % alpha_a
        function alpha_a = upgrade_alpha_a(self)
            alpha_a = self.epsilon_a_0 + 0.5;
        end
        
        % alpha_b
        function alpha_b = upgrade_alpha_b(self)
            alpha_b = self.epsilon_b_0 + 0.5*(self.E.^2 + self.Sigma_E);
        end

        % tau_a
        function tau_a = upgrade_tau_a(self)
            tau_a = self.tau_a_0 + self.num_observation/2;
        end
        
        % tau_b
        function tau_b = upgrade_tau_b(self)
            % temp = 0.5*( (self.yTensor-double(tnprod_new(self.Factors))-self.E).^2);
            Y = self.yTensor;
            X = double(tnprod_new(self.Factors));
            EE2 = sum((self.E(:).^2 + self.Sigma_E(:)));
            err = Y(:)'*Y(:) - 2*Y(:)'*X(:) -2*Y(:)'*self.E(:) + 2*X(:)'*self.E(:) + X(:)'*X(:) + EE2;
            tau_b = self.tau_b_0 + 0.5*err;
            % tau_b = self.tau_b_0 + sum(temp(:));
        end

    end
end


